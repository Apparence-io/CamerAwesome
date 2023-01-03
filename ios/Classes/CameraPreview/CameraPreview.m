//
//  CameraPreview.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraPreview.h"

@implementation CameraPreview {
  dispatch_queue_t _dispatchQueue;
}

- (instancetype)initWithCameraSensor:(CameraSensor)sensor
                        streamImages:(BOOL)streamImages
                         captureMode:(CaptureModes)captureMode
                              result:(nonnull FlutterResult)result
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
                           messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
  self = [super init];
  
  _result = result;
  _messenger = messenger;
  _dispatchQueue = dispatchQueue;
  
  // Creating capture session
  _captureSession = [[AVCaptureSession alloc] init];
  _captureVideoOutput = [AVCaptureVideoDataOutput new];
  _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
  [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
  [_captureSession addOutputWithNoConnections:_captureVideoOutput];
  
  _cameraSensor = sensor;
  _aspectRatio = Ratio4_3;
  
  [self initCameraPreview:sensor];
  
  [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
  
  _captureMode = captureMode;
  
  // By default enable auto flash mode
  _flashMode = AVCaptureFlashModeOff;
  _torchMode = AVCaptureTorchModeOff;
  
  _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
  _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  
  // Controllers init
  _videoController = [[VideoController alloc] initResult:result];
  _imageStreamController = [[ImageStreamController alloc] initWithStreamImages:streamImages];
  _motionController = [[MotionController alloc] init];
  _locationController = [[LocationController alloc] init];
  
  [_motionController startMotionDetection];
  
  [self setBestPreviewQuality];
  
  return self;
}

- (void)setAspectRatio:(AspectRatio)ratio {
  _aspectRatio = ratio;
}

/// Set image stream Flutter sink
- (void)setImageStreamEvent:(FlutterEventSink)imageStreamEventSink {
  if (_imageStreamController != nil) {
    [_imageStreamController setImageStreamEventSink:imageStreamEventSink];
  }
}

/// Set orientation stream Flutter sink
- (void)setOrientationEventSink:(FlutterEventSink)orientationEventSink {
  if (_motionController != nil) {
    [_motionController setOrientationEventSink:orientationEventSink];
  }
}

/// Assign the default preview qualities
- (void)setBestPreviewQuality {
  NSArray *qualities = [CameraQualities captureFormatsForDevice:_captureDevice];
  NSDictionary *firstSizeDict = [qualities count] > 0 ? qualities.lastObject : @{\
    @"width": @3840,\
    @"height": @2160\
  };
  
  CGSize firstSize = CGSizeMake([firstSizeDict[@"width"] floatValue], [firstSizeDict[@"height"] floatValue]);
  [self setCameraPresset:firstSize];
}

/// Save exif preferences when taking picture
- (void)setExifPreferencesGPSLocation:(bool)gpsLocation {
  _saveGPSLocation = gpsLocation;
  
  if (_saveGPSLocation) {
    [_locationController requestWhenInUseAuthorization];
  }
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
  [_captureConnection setVideoMirrored:(_cameraSensor == Front)];
  [_captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
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
    presetSelected = [CameraQualities selectVideoCapturePresset:currentPreviewSize session:_captureSession device:_captureDevice];
  } else {
    // Compute the best quality supported by the camera device
    presetSelected = [CameraQualities selectVideoCapturePresset:_captureSession device:_captureDevice];
  }
  [_captureSession setSessionPreset:presetSelected];
  _currentPresset = presetSelected;
  
  // Get preview size according to presset selected
  _currentPreviewSize = [CameraQualities getSizeForPresset:presetSelected];
  [_videoController setPreviewSize:currentPreviewSize];
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
  
  // Spread resul in controllers
  [_videoController setResult:result];
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
  if (_videoController.isRecording) {
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
- (void)setSensor:(CameraSensor)sensor deviceId:(NSString *)captureDeviceId {
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
  [_videoController setAudioIsDisconnected:YES];
  
  [_captureSession removeOutput:_capturePhotoOutput];
  [_captureSession removeConnection:_captureConnection];
  
  _cameraSensor = sensor;
  _captureDeviceId = captureDeviceId;
  
  // Init the camera preview with the selected sensor
  [self initCameraPreview:sensor];
  
  [self setBestPreviewQuality];
  
  [_captureSession commitConfiguration];
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

/// Trigger focus on device at the specific point of the preview
- (void)focusOnPoint:(CGPoint)position preview:(CGSize)preview {
  NSError *error;
  if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [_captureDevice isFocusPointOfInterestSupported]) {
    if ([_captureDevice lockForConfiguration:&error]) {
      if (error != nil) {
        _result([FlutterError errorWithCode:@"FOCUS_ERROR" message:@"impossible to set focus point" details:@""]);
        return;
      }
      
      [_captureDevice setFocusPointOfInterest:position];
      [_captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
      
      [_captureDevice unlockForConfiguration];
    }
  }
}

/// Get the first available camera on device (front or rear)
- (NSString *)selectAvailableCamera:(CameraSensor)sensor {
  if (_captureDeviceId != nil) {
    return _captureDeviceId;
  }
  
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

- (NSArray *)getSensors:(AVCaptureDevicePosition)position {
  NSMutableArray *sensors = [NSMutableArray new];
  
  NSArray *sensorsType = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, AVCaptureDeviceTypeBuiltInUltraWideCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];

  AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                       discoverySessionWithDeviceTypes:sensorsType
                                                       mediaType:AVMediaTypeVideo
                                                       position:AVCaptureDevicePositionUnspecified];
  
  for (AVCaptureDevice *device in discoverySession.devices) {
    NSString *type;
    if (device.deviceType == AVCaptureDeviceTypeBuiltInTelephotoCamera) {
      type = @"telephoto";
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInUltraWideCamera) {
      type = @"ultraWideAngle";
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInTrueDepthCamera) {
      type = @"trueDepth";
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInWideAngleCamera) {
      type = @"wideAngle";
    } else {
      type = @"unknown";
    }
    
    NSDictionary *sensorData = @{
      @"uid": device.uniqueID,
      @"type": type,
      @"name": device.localizedName,
      @"iso": [NSNumber numberWithFloat:device.ISO],
      @"flashAvailable": [NSNumber numberWithBool:device.flashAvailable],
    };
    
    if (device.position == position) {
      [sensors addObject:sensorData];
    }
  }
  
  return sensors;
}

/// Set capture mode between Photo & Video mode
- (void)setCaptureMode:(CaptureModes)captureMode {
  if (_videoController.isRecording) {
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

# pragma mark - Camera picture

/// Take the picture into the given path
- (void)takePictureAtPath:(NSString *)path {
  // Instanciate camera picture obj
  CameraPictureController *cameraPicture = [[CameraPictureController alloc] initWithPath:path
                                                                             orientation:_motionController.deviceOrientation
                                                                                  sensor:_cameraSensor
                                                                         saveGPSLocation:_saveGPSLocation
                                                                             aspectRatio:_aspectRatio
                                                                                  result:_result
                                                                                callback:^{
    // If flash mode is always on, restore it back after photo is taken
    if (self->_torchMode == AVCaptureTorchModeOn) {
      [self->_captureDevice lockForConfiguration:nil];
      [self->_captureDevice setTorchMode:AVCaptureTorchModeOn];
      [self->_captureDevice unlockForConfiguration];
    }
  }];
  
  // Create settings instance
  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
  [settings setFlashMode:_flashMode];
  [settings setHighResolutionPhotoEnabled:YES];
  
  [_capturePhotoOutput capturePhotoWithSettings:settings
                                       delegate:cameraPicture];
}

# pragma mark - Camera video
/// Record video into the given path
- (void)recordVideoAtPath:(NSString *)path {
  if (_imageStreamController.streamImages) {
    _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"can't record video when image stream is enabled" details:@""]);
  }
  
  if (!_videoController.isRecording) {
    [_videoController recordVideoAtPath:path audioSetupCallback:^{
      [self setUpCaptureSessionForAudio];
    } videoWriterCallback:^{
      if (self->_videoController.isAudioEnabled) {
        [self->_audioOutput setSampleBufferDelegate:self queue:self->_dispatchQueue];
      }
      [self->_captureVideoOutput setSampleBufferDelegate:self queue:self->_dispatchQueue];
    }];
  } else {
    _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"already recording video" details:@""]);
  }
}

/// Pause video recording
- (void)pauseVideoRecording {
  [_videoController pauseVideoRecording];
}

/// Resume video recording after being paused
- (void)resumeVideoRecording {
  [_videoController resumeVideoRecording];
}

/// Stop recording video
- (void)stopRecordingVideo {
  if (_videoController.isRecording) {
    [_videoController stopRecordingVideo];
  } else {
    _result([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"video is not recording" details:@""]);
  }
}

/// Set audio recording mode
- (void)setRecordingAudioMode:(bool)isAudioEnabled {
  if (_videoController.isRecording) {
    _result([FlutterError errorWithCode:@"CHANGE_AUDIO_MODE" message:@"impossible to change audio mode, video already recording" details:@""]);
    return;
  }
  
  [_captureSession beginConfiguration];
  [_videoController setIsAudioEnabled:isAudioEnabled];
  [_videoController setIsAudioSetup:NO];
  [_videoController setAudioIsDisconnected:YES];
  
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
  
  if (_videoController.isRecording) {
    [self setUpCaptureSessionForAudio];
  }
  
  
  [_captureSession commitConfiguration];
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
      [_videoController setIsAudioSetup:YES];
    } else {
      [_videoController setIsAudioSetup:NO];
    }
  }
}

# pragma mark - Camera Delegates

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  if (output == _captureVideoOutput) {
    CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(newBuffer);
    CVPixelBufferRef old = atomic_load(&_latestPixelBuffer);
    while (!atomic_compare_exchange_strong(&_latestPixelBuffer, &old, newBuffer)) {
      old = atomic_load(&_latestPixelBuffer);
    }
    if (old != nil) {
      CFRelease(old);
    }
    if (_onFrameAvailable) {
      _onFrameAvailable();
    }
  }
  
  // Process image stream controller
  if (_imageStreamController.streamImages && !_videoController.isRecording) {
    [_imageStreamController captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection orientation:_motionController.deviceOrientation];
  }
  
  // Process video recording
  if (_videoController.isRecording) {
    [_videoController captureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection captureVideoOutput:_captureVideoOutput];
  }
}

# pragma mark - Data manipulation

/// Used to copy pixels to in-memory buffer
- (CVPixelBufferRef _Nullable)copyPixelBuffer {
  CVPixelBufferRef pixelBuffer = atomic_load(&_latestPixelBuffer);
  while (!atomic_compare_exchange_strong(&_latestPixelBuffer, &pixelBuffer, nil)) {
    pixelBuffer = atomic_load(&_latestPixelBuffer);
  }
  
  return pixelBuffer;
}

@end
