//
//  CameraView.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraView.h"

@implementation CameraView

FourCharCode const videoFormat = kCVPixelFormatType_32BGRA;

- (instancetype)initWithCameraSensor:(CameraSensor)sensor result:(nonnull FlutterResult)result messenger:(NSObject<FlutterBinaryMessenger> *)messenger event:(FlutterEventSink)eventSink {
    self = [super init];
    
    _result = result;
    _messenger = messenger;
    _eventSink = eventSink;

    // Creating capture session
    _captureSession = [[AVCaptureSession alloc] init];
    
    // Creating video output
    _captureVideoOutput = [AVCaptureVideoDataOutput new];
    _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_captureSession addOutputWithNoConnections:_captureVideoOutput];

    // Creating input device
    [self initCamera:sensor];
    
    [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
    
    // By default enable auto flash mode
    _flashMode = AVCaptureFlashModeOff;
    _torchMode = AVCaptureTorchModeOff;
    
    // Video stuff
    _isRecording = false;
    _enableAudio = true;
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    _cameraSensor = sensor;
    
    // Creating motion detection
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 0.2f;
    [self startMyMotionDetect];
    
    return self;
}

- (void)startMyMotionDetect {
    // TODO: Add weakself
    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                        withHandler:^(CMDeviceMotion *data, NSError *error) {
        UIDeviceOrientation newOrientation;
        if(fabs(data.gravity.x) > fabs(data.gravity.y)) {
            // Landscape
            newOrientation = (data.gravity.x >= 0) ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationLandscapeRight;
        } else {
            // Portrait
            newOrientation = (data.gravity.y >= 0) ? UIDeviceOrientationPortraitUpsideDown : UIDeviceOrientationPortrait;
        }
        if (self->_deviceOrientation != newOrientation) {
            self->_deviceOrientation = newOrientation;
            
            NSString *orientationString;
            switch (newOrientation) {
                case UIDeviceOrientationLandscapeLeft:
                    orientationString = @"LANDSCAPE_LEFT";
                    break;
                case UIDeviceOrientationLandscapeRight:
                    orientationString = @"LANDSCAPE_RIGHT";
                    break;
                case UIDeviceOrientationPortrait:
                    orientationString = @"PORTRAIT_UP";
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    orientationString = @"PORTRAIT_DOWN";
                    break;
                default:
                    break;
            }
            if (self->_eventSink != nil) {
                self->_eventSink(orientationString);
            }
        }
    }];
}

- (void)initCamera:(CameraSensor)sensor {
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

- (CGSize)getEffectivPreviewSize {
    return _currentPreviewSize;
}

- (void)setResult:(nonnull FlutterResult)result {
    _result = result;
}

- (void)dispose {
    [self stop];
}

- (void)setPreviewSize:(CGSize)previewSize {
    [self setCameraPresset:previewSize];
}

- (void)start {
    [_captureSession startRunning];
}

- (void)stop {
    [_captureSession stopRunning];
}

- (void)setCaptureMode:(CaptureModes)captureMode {
    
}

- (void)setSensor:(CameraSensor)sensor {
    // First remove all input & output
    [_captureSession beginConfiguration];
    AVCaptureDeviceInput *oldInput = [_captureSession.inputs firstObject];
    [_captureSession removeInput:oldInput];
    [_captureSession removeOutput:_capturePhotoOutput];
    [_captureSession removeConnection:_captureConnection];

    // Init the camera with the selected sensor
    [self initCamera:sensor];

    [_captureSession commitConfiguration];

    _cameraSensor = sensor;
}

- (CGFloat)getMaxZoom {
    return _captureDevice.activeFormat.videoMaxZoomFactor;
}

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

/// Take the picture into the given path
- (void)takePictureAtPath:(NSString *)path {
    
    // Instanciate camera picture obj
    CameraPicture *cameraPicture = [[CameraPicture alloc] initWithPath:path
                                                           orientation:_deviceOrientation
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

- (void)recordVideoAtPath:(NSString *)path {
    if (!_isRecording) {
        // Instanciate camera picture obj
//        CameraVideo *cameraVideo = [[CameraVideo alloc] initWithPath:path
//                                                               orientation:_deviceOrientation
//                                                                    sensor:_cameraSensor
//                                                                    result:_result
//                                                                  callback:^{
//            NSLog(@"DONE VIDEO");
//
//                                                                    self->_result(nil);
//                                                                }];

        if (![self setupWriterForPath:path]) {
            _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"impossible to write video at path" details:path]);
          return;
        }
        _isRecording = YES;
        _videoTimeOffset = CMTimeMake(0, 1);
        _audioTimeOffset = CMTimeMake(0, 1);
        _result(nil);
      } else {
          _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"already recording video" details:@""]);
      }
}

- (void)setUpCaptureSessionForAudio {
  NSError *error = nil;
  // Create a device input with the device and add it to the session.
  // Setup the audio input.
  AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                                           error:&error];
  if (error) {
    _eventSink(@{@"event" : @"error", @"errorDescription" : error.description});
  }
  // Setup the audio output.
  _audioOutput = [[AVCaptureAudioDataOutput alloc] init];

  if ([_captureSession canAddInput:audioInput]) {
    [_captureSession addInput:audioInput];

    if ([_captureSession canAddOutput:_audioOutput]) {
      [_captureSession addOutput:_audioOutput];
      _isAudioSetup = YES;
    } else {
      _eventSink(@{
        @"event" : @"error",
        @"errorDescription" : @"Unable to add Audio input/output to session capture"
      });
      _isAudioSetup = NO;
    }
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
    [_audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
  }

  [_videoWriter addInput:_videoWriterInput];
  [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

  return YES;
}

- (void)stopRecordingVideo {
    if (_isRecording) {
        _isRecording = NO;
        if (_videoWriter.status != AVAssetWriterStatusUnknown) {
          [_videoWriter finishWritingWithCompletionHandler:^{
            if (self->_videoWriter.status == AVAssetWriterStatusCompleted) {
                self->_result(nil);
            } else {
              self->_eventSink(@{
                @"event" : @"error",
                @"errorDescription" : @"AVAssetWriter could not finish writing!"
              });
            }
          }];
        }
      } else {
          _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"video is not recording" details:@""]);
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
        _eventSink(@{
          @"event" : @"error",
          @"errorDescription" : @"sample buffer is not ready. Skipping sample"
        });
        return;
      }
//      if (_isStreamingImages) {
//        if (_imageStreamHandler.eventSink) {
//          CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//          CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
//
//          size_t imageWidth = CVPixelBufferGetWidth(pixelBuffer);
//          size_t imageHeight = CVPixelBufferGetHeight(pixelBuffer);
//
//          NSMutableArray *planes = [NSMutableArray array];
//
//          const Boolean isPlanar = CVPixelBufferIsPlanar(pixelBuffer);
//          size_t planeCount;
//          if (isPlanar) {
//            planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
//          } else {
//            planeCount = 1;
//          }
//
//          for (int i = 0; i < planeCount; i++) {
//            void *planeAddress;
//            size_t bytesPerRow;
//            size_t height;
//            size_t width;
//
//            if (isPlanar) {
//              planeAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
//              bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
//              height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
//              width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i);
//            } else {
//              planeAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
//              bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
//              height = CVPixelBufferGetHeight(pixelBuffer);
//              width = CVPixelBufferGetWidth(pixelBuffer);
//            }
//
//            NSNumber *length = @(bytesPerRow * height);
//            NSData *bytes = [NSData dataWithBytes:planeAddress length:length.unsignedIntegerValue];
//
//            NSMutableDictionary *planeBuffer = [NSMutableDictionary dictionary];
//            planeBuffer[@"bytesPerRow"] = @(bytesPerRow);
//            planeBuffer[@"width"] = @(width);
//            planeBuffer[@"height"] = @(height);
//            planeBuffer[@"bytes"] = [FlutterStandardTypedData typedDataWithBytes:bytes];
//
//            [planes addObject:planeBuffer];
//          }
//
//          NSMutableDictionary *imageBuffer = [NSMutableDictionary dictionary];
//          imageBuffer[@"width"] = [NSNumber numberWithUnsignedLong:imageWidth];
//          imageBuffer[@"height"] = [NSNumber numberWithUnsignedLong:imageHeight];
//          imageBuffer[@"format"] = @(videoFormat);
//          imageBuffer[@"planes"] = planes;
//
//          _imageStreamHandler.eventSink(imageBuffer);
//
//          CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
//        }
//      }
      if (_isRecording) {
        if (_videoWriter.status == AVAssetWriterStatusFailed) {
          _eventSink(@{
            @"event" : @"error",
            @"errorDescription" : [NSString stringWithFormat:@"%@", _videoWriter.error]
          });
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

# pragma mark - Flutter Delegates

/// Used to copy pixels to in-memory buffer
- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    
    return pixelBuffer;
}

@end
