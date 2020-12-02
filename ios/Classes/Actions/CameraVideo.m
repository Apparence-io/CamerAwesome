//
//  CameraVideo.m
//  Pods
//
//  Created by Dimitri Dessus on 02/12/2020.
//

// This is all related stuff to video recording
FourCharCode const videoFormat = kCVPixelFormatType_32BGRA;

# pragma mark - User actions
/// Record video into the given path
- (void)recordVideoAtPath:(NSString *)path {
    if (!_isRecording) {
        
        if (![self setupWriterForPath:path]) {
            _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to write video at path" details:path]);
            return;
        }
        _isRecording = YES;
        _videoTimeOffset = CMTimeMake(0, 1);
        _audioTimeOffset = CMTimeMake(0, 1);
        _videoIsDisconnected = NO;
        _audioIsDisconnected = NO;
        _result(nil);
    } else {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"already recording video" details:@""]);
    }
}

/// Stop recording video
- (void)stopRecordingVideo {
    if (_isRecording) {
        _isRecording = NO;
        if (_videoWriter.status != AVAssetWriterStatusUnknown) {
            [_videoWriter finishWritingWithCompletionHandler:^{
                if (self->_videoWriter.status == AVAssetWriterStatusCompleted) {
                    self->_result(nil);
                } else {
                    _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to completely write video" details:@""]);
                }
            }];
        }
    } else {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"video is not recording" details:@""]);
    }
}

/// Set audio recording mode
- (void)setRecordingAudioMode:(bool)enableAudio {
    _enableAudio = enableAudio;
    _isAudioSetup = NO;
}

# pragma mark - Recording
- (void)captureVideo:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (_isRecording) {
        if (_videoWriter.status == AVAssetWriterStatusFailed) {
            _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to write video" details:[NSString stringWithFormat:@"%@", _videoWriter.error]]);
            return;
        }
        
        CFRetain(sampleBuffer);
        CMTime currentSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if (_videoWriter.status != AVAssetWriterStatusWriting) {
            [_videoWriter startWriting];
            [_videoWriter startSessionAtSourceTime:currentSampleTime];
        }
        
        if (output == _captureVideoOutput) {
            if (_videoIsDisconnected) {
                _videoIsDisconnected = NO;
                
                if (_videoTimeOffset.value == 0) {
                    _videoTimeOffset = CMTimeSubtract(currentSampleTime, _lastVideoSampleTime);
                } else {
                    CMTime offset = CMTimeSubtract(currentSampleTime, _lastVideoSampleTime);
                    _videoTimeOffset = CMTimeAdd(_videoTimeOffset, offset);
                }
                
                return;
            }
            
            _lastVideoSampleTime = currentSampleTime;
            
            CVPixelBufferRef nextBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            CMTime nextSampleTime = CMTimeSubtract(_lastVideoSampleTime, _videoTimeOffset);
            [_videoAdaptor appendPixelBuffer:nextBuffer withPresentationTime:nextSampleTime];
        } else {
            CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
            
            if (dur.value > 0) {
                currentSampleTime = CMTimeAdd(currentSampleTime, dur);
            }
            
            if (_audioIsDisconnected) {
                _audioIsDisconnected = NO;
                
                if (_audioTimeOffset.value == 0) {
                    _audioTimeOffset = CMTimeSubtract(currentSampleTime, _lastAudioSampleTime);
                } else {
                    CMTime offset = CMTimeSubtract(currentSampleTime, _lastAudioSampleTime);
                    _audioTimeOffset = CMTimeAdd(_audioTimeOffset, offset);
                }
                
                return;
            }
            
            _lastAudioSampleTime = currentSampleTime;
            
            if (_audioTimeOffset.value != 0) {
                CFRelease(sampleBuffer);
                sampleBuffer = [self adjustTime:sampleBuffer by:_audioTimeOffset];
            }
            
            [self newAudioSample:sampleBuffer];
        }
        
        CFRelease(sampleBuffer);
    }
}

- (BOOL)setupWriterForPath:(NSString *)path {
    NSError *error = nil;
    NSURL *outputURL;
    if (path != nil) {
        outputURL = [NSURL fileURLWithPath:path];
    } else {
        return NO;
    }
    if (_enableAudio && !_isAudioSetup) {
        [self setUpCaptureSessionForAudio];
    }
    _videoWriter = [[AVAssetWriter alloc] initWithURL:outputURL
                                             fileType:AVFileTypeQuickTimeMovie
                                                error:&error];
    NSParameterAssert(_videoWriter);
    if (error) {
        _eventSink(@{@"event" : @"error", @"errorDescription" : error.description});
        return NO;
    }
    NSDictionary *videoSettings = [NSDictionary
                                   dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:_currentPreviewSize.height], AVVideoWidthKey,
                                   [NSNumber numberWithInt:_currentPreviewSize.width], AVVideoHeightKey,
                                   nil];
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                           outputSettings:videoSettings];
    
    _videoAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput
                     sourcePixelBufferAttributes:@{
                         (NSString *)kCVPixelBufferPixelFormatTypeKey : @(videoFormat)
                     }];
    
    NSParameterAssert(_videoWriterInput);
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    
    // Add the audio input
    if (_enableAudio) {
        AudioChannelLayout acl;
        bzero(&acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        NSDictionary *audioOutputSettings = nil;
        // Both type of audio inputs causes output video file to be corrupted.
        audioOutputSettings = [NSDictionary
                               dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                               [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                               [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                               [NSData dataWithBytes:&acl length:sizeof(acl)],
                               AVChannelLayoutKey, nil];
        _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                               outputSettings:audioOutputSettings];
        _audioWriterInput.expectsMediaDataInRealTime = YES;
        
        [_videoWriter addInput:_audioWriterInput];
        [_audioOutput setSampleBufferDelegate:self queue:_dispatchQueue];
    }
    
    [_videoWriter addInput:_videoWriterInput];
    [_captureVideoOutput setSampleBufferDelegate:self queue:_dispatchQueue];
    
    return YES;
}

- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset CF_RETURNS_RETAINED {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

# pragma mark - Audio
- (void)setUpCaptureSessionForAudio {
    NSError *error = nil;
    // Create a device input with the device and add it to the session.
    // Setup the audio input.
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                                             error:&error];
    if (error) {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"error when trying to setup audio capture" details:error.description]);
    }
    // Setup the audio output.
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    if ([_captureSession canAddInput:audioInput]) {
        [_captureSession addInput:audioInput];
        
        if ([_captureSession canAddOutput:_audioOutput]) {
            [_captureSession addOutput:_audioOutput];
            _isAudioSetup = YES;
        } else {
            _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to add audio canal to session capture" details:@""]);
            _isAudioSetup = NO;
        }
    }
}

- (void)newAudioSample:(CMSampleBufferRef)sampleBuffer {
    if (_videoWriter.status != AVAssetWriterStatusWriting) {
        if (_videoWriter.status == AVAssetWriterStatusFailed) {
            _eventSink(@{
                @"event" : @"error",
                @"errorDescription" : [NSString stringWithFormat:@"%@", _videoWriter.error]
                       });
        }
        return;
    }
    if (_audioWriterInput.readyForMoreMediaData) {
        if (![_audioWriterInput appendSampleBuffer:sampleBuffer]) {
            _eventSink(@{
                @"event" : @"error",
                @"errorDescription" :
                    [NSString stringWithFormat:@"%@", @"Unable to write to audio input"]
                       });
        }
    }
}
