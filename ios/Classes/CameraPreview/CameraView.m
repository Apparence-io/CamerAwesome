//
//  CameraView.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraView.h"

@implementation CameraView {
    dispatch_queue_t _dispatchQueue;
}

- (instancetype)initWithCameraSensor:(CameraSensor)sensor
                        streamImages:(BOOL)streamImages
                         captureMode:(CaptureModes)captureMode
                              result:(nonnull FlutterResult)result
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
                           messenger:(NSObject<FlutterBinaryMessenger> *)messenger
                    orientationEvent:(FlutterEventSink)orientationEventSink
                 videoRecordingEvent:(FlutterEventSink)videoRecordingEventSink
                    imageStreamEvent:(FlutterEventSink)imageStreamEventSink {
    self = [super init];
    
    _result = result;
    _messenger = messenger;
    _dispatchQueue = dispatchQueue;
    
    // Events
//    _orientationEventSink = orientationEventSink;
    _videoRecordingEventSink = videoRecordingEventSink;
    _imageStreamEventSink = imageStreamEventSink;
    
    // Creating capture session
    _captureSession = [[AVCaptureSession alloc] init];
    
    // Creating video output
    _captureVideoOutput = [AVCaptureVideoDataOutput new];
    _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_captureSession addOutputWithNoConnections:_captureVideoOutput];
    
    // Creating input device
    [self initCameraPreview:sensor];
    
    [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
    
    _captureMode = captureMode;
    _streamImages = streamImages;
    
    // By default enable auto flash mode
    _flashMode = AVCaptureFlashModeOff;
    _torchMode = AVCaptureTorchModeOff;
    
    // Video stuff
    _isRecording = false;
    _enableAudio = true;
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    _cameraSensor = sensor;
    
    // Creating motion detection controller
    _motionController = [[MotionController alloc] initWithEventSink:orientationEventSink];
    [_motionController startMotionDetection];
    
    return self;
}

/// Init camera preview with Front or Rear sensor
- (void)initCameraPreview:(CameraSensor)sensor {
    // Here we set a preset which wont crash the device before switching to front or back
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    NSError *error;
    _captureDevice = [AVCaptureDevice deviceWithUniqueID:[self selectAvailableCamera:sensor]];
    _captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (error != nil) {
        _result([FlutterError errorWithCode:@"CANNOT_OPEN_CAMERA" message:@"can't attach device to input" details:[error localizedDescription]]);
        return;
    }
    
    // Create connection
    _captureConnection = [AVCaptureConnection connectionWithInputPorts:_captureVideoInput.ports
                                                                output:_captureVideoOutput];
    
    // Attaching to session
    [_captureSession addInputWithNoConnections:_captureVideoInput];
    [_captureSession addConnection:_captureConnection];
    
    // Creating photo output
    _capturePhotoOutput = [AVCapturePhotoOutput new];
    [_capturePhotoOutput setHighResolutionCaptureEnabled:YES];
    [_captureSession addOutput:_capturePhotoOutput];
    
    // Mirror the preview only on portrait mode
    [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
    [_captureConnection setVideoMirrored:(_cameraSensor == Back)];
    [_captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [self setCameraPresset:CGSizeMake(0, 0)];
}

- (void)dealloc {
  if (_latestPixelBuffer) {
    CFRelease(_latestPixelBuffer);
  }
  [_motionController startMotionDetection];
}

/// Set camera preview size
- (void)setCameraPresset:(CGSize)currentPreviewSize {
    NSString *presetSelected;
    if (!CGSizeEqualToSize(CGSizeZero, currentPreviewSize)) {
        // Try to get the quality requested
        presetSelected = [CameraQualities selectVideoCapturePresset:currentPreviewSize session:_captureSession];
    } else {
        // Compute the best quality supported by the camera device
        presetSelected = [CameraQualities selectVideoCapturePresset:_captureSession];
    }
    [_captureSession setSessionPreset:presetSelected];
    _currentPresset = presetSelected;
    
    // Get preview size according to presset selected
    _currentPreviewSize = [CameraQualities getSizeForPresset:presetSelected];
}

/// Get current video prewiew size
- (CGSize)getEffectivPreviewSize {
    return _currentPreviewSize;
}

// Get max zoom level
- (CGFloat)getMaxZoom {
    return _captureDevice.activeFormat.videoMaxZoomFactor;
}

/// Set Flutter results
- (void)setResult:(FlutterResult _Nonnull)result {
    _result = result;
}

/// Dispose camera inputs & outputs
- (void)dispose {
    [self stop];
    
    for (AVCaptureInput *input in [_captureSession inputs]) {
        [_captureSession removeInput:input];
    }
    for (AVCaptureOutput *output in [_captureSession outputs]) {
        [_captureSession removeOutput:output];
    }
}

/// Set preview size resolution
- (void)setPreviewSize:(CGSize)previewSize {
    if (_isRecording) {
        _result([FlutterError errorWithCode:@"PREVIEW_SIZE" message:@"impossible to change preview size, video already recording" details:@""]);
        return;
    }
    
    [self setCameraPresset:previewSize];
}

/// Start camera preview
- (void)start {
    [_captureSession startRunning];
}

/// Stop camera preview
- (void)stop {
    [_captureSession stopRunning];
}

/// Set sensor between Front & Rear camera
- (void)setSensor:(CameraSensor)sensor {
    // First remove all input & output
    [_captureSession beginConfiguration];
    
    // Only remove camera channel but keep audio
    for (AVCaptureInput *input in [_captureSession inputs]) {
        for (AVCaptureInputPort *port in input.ports) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                [_captureSession removeInput:input];
                break;
            }
        }
    }
    _audioIsDisconnected = YES;

    [_captureSession removeOutput:_capturePhotoOutput];
    [_captureSession removeConnection:_captureConnection];
    
    // Init the camera preview with the selected sensor
    [self initCameraPreview:sensor];
    
    [_captureSession commitConfiguration];
    
    _cameraSensor = sensor;
}

/// Set zoom level
- (void)setZoom:(float)value {
    CGFloat maxZoom = _captureDevice.activeFormat.videoMaxZoomFactor;
    CGFloat scaledZoom = value * (maxZoom - 1.0f) + 1.0f;
    
    NSError *error;
    if ([_captureDevice lockForConfiguration:&error]) {
        _captureDevice.videoZoomFactor = scaledZoom;
        [_captureDevice unlockForConfiguration];
    } else {
        _result([FlutterError errorWithCode:@"ZOOM_NOT_SET" message:@"can't set the zoom value" details:[error localizedDescription]]);
    }
}

/// Set flash mode
- (void)setFlashMode:(CameraFlashMode)flashMode {
    if (![_captureDevice hasFlash]) {
        _result([FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"flash is not supported on this device" details:@""]);
        return;
    }
    
    if (_cameraSensor == Front) {
        _result([FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"can't set flash for portrait mode" details:@""]);
        return;
    }
    
    NSError *error;
    [_captureDevice lockForConfiguration:&error];
    if (error != nil) {
        _result([FlutterError errorWithCode:@"FLASH_ERROR" message:@"impossible to change configuration" details:@""]);
        return;
    }
    
    switch (flashMode) {
        case None:
            _torchMode = AVCaptureTorchModeOff;
            _flashMode = AVCaptureFlashModeOff;
            break;
        case On:
            _torchMode = AVCaptureTorchModeOff;
            _flashMode = AVCaptureFlashModeOn;
            break;
        case Auto:
            _torchMode = AVCaptureTorchModeAuto;
            _flashMode = AVCaptureFlashModeAuto;
            break;
        case Always:
            _torchMode = AVCaptureTorchModeOn;
            _flashMode = AVCaptureFlashModeOn;
            break;
        default:
            _torchMode = AVCaptureTorchModeAuto;
            _flashMode = AVCaptureFlashModeAuto;
            break;
    }
    [_captureDevice setTorchMode:_torchMode];
    [_captureDevice unlockForConfiguration];
    
    _result(nil);
}

/// Trigger focus on device at the center of the preview
- (void)instantFocus {
    NSError *error;
    
    // Get center point of the preview size
    double focus_x = _currentPreviewSize.width / 2;
    double focus_y = _currentPreviewSize.height / 2;
    
    CGPoint thisFocusPoint = [_previewLayer captureDevicePointOfInterestForPoint:CGPointMake(focus_x, focus_y)];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [_captureDevice isFocusPointOfInterestSupported]) {
        if ([_captureDevice lockForConfiguration:&error]) {
            if (error != nil) {
                _result([FlutterError errorWithCode:@"FOCUS_ERROR" message:@"impossible to set focus point" details:@""]);
                return;
            }
            
            [_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [_captureDevice setFocusPointOfInterest:thisFocusPoint];
            
            [_captureDevice unlockForConfiguration];
        }
    }
}

/// Get the first available camera on device (front or rear)
- (NSString *)selectAvailableCamera:(CameraSensor)sensor {
    NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                         discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                         mediaType:AVMediaTypeVideo
                                                         position:AVCaptureDevicePositionUnspecified];
    devices = discoverySession.devices;
    
    NSInteger cameraType = (sensor == Front) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    for (AVCaptureDevice *device in devices) {
        if ([device position] == cameraType) {
            return [device uniqueID];
        }
    }
    return nil;
}

/// Set capture mode between Photo & Video mode
- (void)setCaptureMode:(CaptureModes)captureMode {
    if (_isRecording) {
        _result([FlutterError errorWithCode:@"CAPTURE_MODE" message:@"impossible to change capture mode, video already recording" details:@""]);
        return;
    }
    
    _captureMode = captureMode;
    
    if (captureMode == Video) {
        [self setUpCaptureSessionForAudio];
    }
}

- (void)refresh {
    if ([_captureSession isRunning]) {
        [self stop];
    }
    [self start];
}

# pragma mark - Camera action stuff
// Both of these need to access value from preview
// We do not create separate object before it seems to be
// a mess with pointer to pass... :/

/// Take the picture into the given path
- (void)takePictureAtPath:(NSString *)path {
    
    // Instanciate camera picture obj
    CameraPictureController *cameraPicture = [[CameraPictureController alloc] initWithPath:path
                                                                               orientation:_motionController.deviceOrientation
                                                                                    sensor:_cameraSensor
                                                                                    result:_result
                                                                                  callback:^{
        // If flash mode is always on, restore it back after photo is taken
        if (self->_torchMode == AVCaptureTorchModeOn) {
            [self->_captureDevice lockForConfiguration:nil];
            [self->_captureDevice setTorchMode:AVCaptureTorchModeOn];
            [self->_captureDevice unlockForConfiguration];
        }
        
        self->_result(nil);
    }];
    
    // Create settings instance
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    [settings setFlashMode:_flashMode];
    
    [_capturePhotoOutput capturePhotoWithSettings:settings
                                         delegate:cameraPicture];
}


// This is all related stuff to video recording
FourCharCode const videoFormat = kCVPixelFormatType_32BGRA;

# pragma mark - User actions
/// Record video into the given path
- (void)recordVideoAtPath:(NSString *)path {
    if (_streamImages) {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"can't record video when image stream is enabled" details:@""]);
    }
    
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
                    self->_result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to completely write video" details:@""]);
                }
            }];
        }
    } else {
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"video is not recording" details:@""]);
    }
}

/// Set audio recording mode
- (void)setRecordingAudioMode:(bool)enableAudio {
    if (_isRecording) {
        _result([FlutterError errorWithCode:@"CHANGE_AUDIO_MODE" message:@"impossible to change audio mode, video already recording" details:@""]);
        return;
    }
    
    [_captureSession beginConfiguration];
    _enableAudio = enableAudio;
    _isAudioSetup = NO;
    _audioIsDisconnected = YES;
    
    // Only remove audio channel input but keep video
    for (AVCaptureInput *input in [_captureSession inputs]) {
        for (AVCaptureInputPort *port in input.ports) {
            if ([[port mediaType] isEqual:AVMediaTypeAudio]) {
                [_captureSession removeInput:input];
                break;
            }
        }
    }
    // Only remove audio channel output but keep video
    [_captureSession removeOutput:_audioOutput];
    
    if (_enableAudio) {
        [self setUpCaptureSessionForAudio];
    }
    
    [_captureSession commitConfiguration];
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

/// Setup video channel & write file on path
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
        _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to create video writer" details:[NSString stringWithFormat:@"%@", error.description]]);
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

# pragma mark - Audio
/// Setup audio channel to record audio
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
            _isAudioSetup = NO;
        }
    }
}

/// Append audio data
- (void)newAudioSample:(CMSampleBufferRef)sampleBuffer {
    if (_videoWriter.status != AVAssetWriterStatusWriting) {
        if (_videoWriter.status == AVAssetWriterStatusFailed) {
            _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"writing video failed" details:[NSString stringWithFormat:@"%@", _videoWriter.error]]);
        }
        return;
    }
    if (_audioWriterInput.readyForMoreMediaData) {
        if (![_audioWriterInput appendSampleBuffer:sampleBuffer]) {
            _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"adding audio channel failed" details:[NSString stringWithFormat:@"%@", _videoWriter.error]]);
        }
    }
}


# pragma mark - Camera Delegates

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (output == _captureVideoOutput) {
        CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CFRetain(newBuffer);
        CVPixelBufferRef old = _latestPixelBuffer;
        while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
            old = _latestPixelBuffer;
        }
        if (old != nil) {
            CFRelease(old);
        }
        if (_onFrameAvailable) {
            _onFrameAvailable();
        }
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        _videoRecordingEventSink(@"sample buffer is not ready. Skipping sample");
        return;
    }
    
    if (_streamImages && _imageStreamEventSink) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

        const Boolean isPlanar = CVPixelBufferIsPlanar(pixelBuffer);
        size_t planeCount;
        if (isPlanar) {
            planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
        } else {
            planeCount = 1;
        }
        
        FlutterStandardTypedData *data;
        for (int i = 0; i < planeCount; i++) {
            void *planeAddress;
            size_t bytesPerRow;
            size_t height;
            size_t width;
            
            if (isPlanar) {
                planeAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
                bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
                height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
                width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i);
            } else {
                planeAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
                bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
                height = CVPixelBufferGetHeight(pixelBuffer);
                width = CVPixelBufferGetWidth(pixelBuffer);
            }
            
            NSNumber *length = @(bytesPerRow * height);
            NSData *bytes = [NSData dataWithBytes:planeAddress length:length.unsignedIntegerValue];
            data = [FlutterStandardTypedData typedDataWithBytes:bytes];
        }

        // Only send bytes for now
        _imageStreamEventSink(data);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
    
    if (_isRecording) {
        if (_videoWriter.status == AVAssetWriterStatusFailed) {
            _videoRecordingEventSink([NSString stringWithFormat:@"video writing failed: %@", [_videoWriter.error localizedDescription]]);
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

# pragma mark - Data manipulation

/// Used to copy pixels to in-memory buffer
- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    
    return pixelBuffer;
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

@end
