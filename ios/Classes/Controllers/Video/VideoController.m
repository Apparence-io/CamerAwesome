//
//  VideoController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import "VideoController.h"

FourCharCode const videoFormat = kCVPixelFormatType_32BGRA;

@implementation VideoController

- (instancetype)initWithEventSink:(FlutterEventSink)videoRecordingEventSink result:(FlutterResult)result {
    self = [super init];
    _videoRecordingEventSink = videoRecordingEventSink;
    _result = result;
    _isRecording = NO;
    _isAudioEnabled = YES;
    
    return self;
}

# pragma mark - User video interactions

/// Start recording video at given path
- (void)recordVideoAtPath:(NSString *)path audioSetupCallback:(OnAudioSetup)audioSetupCallback videoWriterCallback:(OnVideoWriterSetup)videoWriterCallback {
    // Create audio & video writer
    if (![self setupWriterForPath:path audioSetupCallback:audioSetupCallback]) {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to write video at path" details:path]);
        return;
    }
    // Call parent to add delegates for video & audio (if needed)
    videoWriterCallback();
    
    _isRecording = YES;
    _videoTimeOffset = CMTimeMake(0, 1);
    _audioTimeOffset = CMTimeMake(0, 1);
    _videoIsDisconnected = NO;
    _audioIsDisconnected = NO;
    _result(nil);
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
                    self->_result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to completely write video" details:@""]);
                }
            }];
        }
    } else {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"video is not recording" details:@""]);
    }
}

# pragma mark - Audio & Video writers

/// Setup video channel & write file on path
- (BOOL)setupWriterForPath:(NSString *)path audioSetupCallback:(OnAudioSetup)audioSetupCallback {
    NSError *error = nil;
    NSURL *outputURL;
    if (path != nil) {
        outputURL = [NSURL fileURLWithPath:path];
    } else {
        return NO;
    }
    if (_isAudioEnabled && !_isAudioSetup) {
        audioSetupCallback();
    }
    _videoWriter = [[AVAssetWriter alloc] initWithURL:outputURL
                                             fileType:AVFileTypeQuickTimeMovie
                                                error:&error];
    NSParameterAssert(_videoWriter);
    if (error) {
        _videoRecordingEventSink([NSString stringWithFormat:@"impossible to create video writer : %@", error.description]);
        return NO;
    }
    NSDictionary *videoSettings = [NSDictionary
                                   dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:_previewSize.height], AVVideoWidthKey,
                                   [NSNumber numberWithInt:_previewSize.width], AVVideoHeightKey,
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
    
    if (_isAudioEnabled) {
        AudioChannelLayout acl;
        bzero(&acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        NSDictionary *audioOutputSettings = nil;

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
    }
    
    [_videoWriter addInput:_videoWriterInput];
    
    return YES;
}

/// Append audio data
- (void)newAudioSample:(CMSampleBufferRef)sampleBuffer {
    if (_videoWriter.status != AVAssetWriterStatusWriting) {
        if (_videoWriter.status == AVAssetWriterStatusFailed) {
            _videoRecordingEventSink([NSString stringWithFormat:@"writing video failed : %@", _videoWriter.error]);
        }
        return;
    }
    if (_audioWriterInput.readyForMoreMediaData) {
        if (![_audioWriterInput appendSampleBuffer:sampleBuffer]) {
            _videoRecordingEventSink([NSString stringWithFormat:@"adding audio channel failed : %@", _videoWriter.error]);
        }
    }
}

/// Adjust time to sync audio & video
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

# pragma mark - Camera Delegates
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection captureVideoOutput:(AVCaptureVideoDataOutput *)captureVideoOutput {
    if (_videoWriter.status == AVAssetWriterStatusFailed) {
        _videoRecordingEventSink([NSString stringWithFormat:@"impossible to write video : %@", _videoWriter.error]);
        return;
    }
    
    CFRetain(sampleBuffer);
    CMTime currentSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if (_videoWriter.status != AVAssetWriterStatusWriting) {
        [_videoWriter startWriting];
        [_videoWriter startSessionAtSourceTime:currentSampleTime];
    }
    
    if (output == captureVideoOutput) {
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

# pragma mark - Setter
- (void)setIsAudioEnabled:(bool)isAudioEnabled {
    _isAudioEnabled = isAudioEnabled;
}
- (void)setIsAudioSetup:(bool)isAudioSetup {
    _isAudioSetup = isAudioSetup;
}

- (void)setResult:(FlutterResult _Nonnull)result {
    _result = result;
}

- (void)setPreviewSize:(CGSize)previewSize {
    _previewSize = previewSize;
}

- (void)setVideoIsDisconnected:(bool)videoIsDisconnected {
    _videoIsDisconnected = videoIsDisconnected;
}

- (void)setAudioIsDisconnected:(bool)audioIsDisconnected {
    _audioIsDisconnected = audioIsDisconnected;
}

@end
