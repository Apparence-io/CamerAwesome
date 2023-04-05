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
                   mirrorFrontCamera:(BOOL)mirrorFrontCamera
                enablePhysicalButton:(BOOL)enablePhysicalButton
                     aspectRatioMode:(AspectRatio)aspectRatioMode
                         captureMode:(CaptureModes)captureMode
                          completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion
                       dispatchQueue:(dispatch_queue_t)dispatchQueue {
  self = [super init];
  
  _completion = completion;
  _dispatchQueue = dispatchQueue;
  
  // Creating capture session
  _captureSession = [[AVCaptureSession alloc] init];
  _captureVideoOutput = [AVCaptureVideoDataOutput new];
  _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
  [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
  [_captureSession addOutputWithNoConnections:_captureVideoOutput];
  
  _cameraSensor = sensor;
  _aspectRatio = aspectRatioMode;
  _mirrorFrontCamera = mirrorFrontCamera;
  
  [self initCameraPreview:sensor];
  
  [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
  
  _captureMode = captureMode;
  
  // By default enable auto flash mode
  _flashMode = AVCaptureFlashModeOff;
  _torchMode = AVCaptureTorchModeOff;
  
  _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
  _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  
  // Controllers init
  _videoController = [[VideoController alloc] init];
  _imageStreamController = [[ImageStreamController alloc] initWithStreamImages:streamImages];
  _motionController = [[MotionController alloc] init];
  _locationController = [[LocationController alloc] init];
  _physicalButtonController = [[PhysicalButtonController alloc] init];
  
  [_motionController startMotionDetection];
  
  if (enablePhysicalButton) {
    [_physicalButtonController startListening];
  }
  
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

/// Set physical button Flutter sink
- (void)setPhysicalButtonEventSink:(FlutterEventSink)physicalButtonEventSink {
  if (_physicalButtonController != nil) {
    [_physicalButtonController setPhysicalButtonEventSink:physicalButtonEventSink];
  }
}

/// Assign the default preview qualities
- (void)setBestPreviewQuality {
  NSArray *qualities = [CameraQualities captureFormatsForDevice:_captureDevice];
  PreviewSize *firstPreviewSize = [qualities count] > 0 ? qualities.lastObject : [PreviewSize makeWithWidth:@3840 height:@2160];
  
  CGSize firstSize = CGSizeMake([firstPreviewSize.width floatValue], [firstPreviewSize.height floatValue]);
  [self setCameraPresset:firstSize];
}

/// Save exif preferences when taking picture
- (void)setExifPreferencesGPSLocation:(bool)gpsLocation completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
  _saveGPSLocation = gpsLocation;
  
  if (_saveGPSLocation) {
    [_locationController requestWhenInUseAuthorizationOnGranted:^{
      completion(@(YES), nil);
    } declined:^{
      completion(@(NO), nil);
    }];
  } else {
    completion(@(YES), nil);
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
    _completion(nil, [FlutterError errorWithCode:@"CANNOT_OPEN_CAMERA" message:@"can't attach device to input" details:[error localizedDescription]]);
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
  CGSize preview = currentPreviewSize;
  if (_imageStreamController.streamImages) {
    // force preview to HD for image stream
    preview = CGSizeMake(720, 1280);
  }
  
  NSString *presetSelected;
  if (!CGSizeEqualToSize(CGSizeZero, preview)) {
    // Try to get the quality requested
    presetSelected = [CameraQualities selectVideoCapturePresset:preview session:_captureSession device:_captureDevice];
  } else {
    // Compute the best quality supported by the camera device
    presetSelected = [CameraQualities selectVideoCapturePresset:_captureSession device:_captureDevice];
  }
  [_captureSession setSessionPreset:presetSelected];
  _currentPresset = presetSelected;
  
  // Get preview size according to presset selected
  _currentPreviewSize = [CameraQualities getSizeForPresset:presetSelected];
  
  [_videoController setPreviewSize:_currentPreviewSize];
}

/// Get current video prewiew size
- (CGSize)getEffectivPreviewSize {
  return _currentPreviewSize;
}

// Get max zoom level
- (CGFloat)getMaxZoom {
  CGFloat maxZoom = _captureDevice.activeFormat.videoMaxZoomFactor;
  // Not sure why on iPhone 14 Pro, zoom at 90 not working, so let's block to 50 which is very high
  return maxZoom > 50.0 ? 50.0 : maxZoom;
}

/// Dispose camera inputs & outputs
- (void)dispose {
  [self stop];
  [self.physicalButtonController stopListening];
  
  for (AVCaptureInput *input in [_captureSession inputs]) {
    [_captureSession removeInput:input];
  }
  for (AVCaptureOutput *output in [_captureSession outputs]) {
    [_captureSession removeOutput:output];
  }
}

/// Set preview size resolution
- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (_videoController.isRecording) {
    *error = [FlutterError errorWithCode:@"PREVIEW_SIZE" message:@"impossible to change preview size, video already recording" details:@""];
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
- (void)setZoom:(float)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  CGFloat maxZoom = [self getMaxZoom];
  CGFloat scaledZoom = value * (maxZoom - 1.0f) + 1.0f;
  
  NSError *zoomError;
  if ([_captureDevice lockForConfiguration:&zoomError]) {
    _captureDevice.videoZoomFactor = scaledZoom;
    [_captureDevice unlockForConfiguration];
  } else {
    *error = [FlutterError errorWithCode:@"ZOOM_NOT_SET" message:@"can't set the zoom value" details:[zoomError localizedDescription]];
  }
}

- (void)setBrightness:(NSNumber *)brightness error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  NSError *brightnessError = nil;
  if ([_captureDevice lockForConfiguration:&brightnessError]) {
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    if ([_captureDevice isExposureModeSupported:exposureMode]) {
      [_captureDevice setExposureMode:exposureMode];
    }
    
    CGFloat minExposureTargetBias = _captureDevice.minExposureTargetBias;
    CGFloat maxExposureTargetBias = _captureDevice.maxExposureTargetBias;
    
    CGFloat exposureTargetBias = minExposureTargetBias + (maxExposureTargetBias - minExposureTargetBias) * [brightness floatValue];
    exposureTargetBias = MAX(minExposureTargetBias, MIN(maxExposureTargetBias, exposureTargetBias));
    
    [_captureDevice setExposureTargetBias:exposureTargetBias completionHandler:nil];
    [_captureDevice unlockForConfiguration];
  } else {
    *error = [FlutterError errorWithCode:@"BRIGHTNESS_NOT_SET" message:@"can't set the brightness value" details:[brightnessError localizedDescription]];
  }
}

- (void)setMirrorFrontCamera:(bool)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  _mirrorFrontCamera = value;
}

/// Set flash mode
- (void)setFlashMode:(CameraFlashMode)flashMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (![_captureDevice hasFlash]) {
    *error = [FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"flash is not supported on this device" details:@""];
    return;
  }
  
  if (_cameraSensor == Front) {
    *error = [FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"can't set flash for portrait mode" details:@""];
    return;
  }
  
  NSError *lockError;
  [_captureDevice lockForConfiguration:&lockError];
  if (lockError != nil) {
    *error = [FlutterError errorWithCode:@"FLASH_ERROR" message:@"impossible to change configuration" details:@""];
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
}

/// Trigger focus on device at the specific point of the preview
- (void)focusOnPoint:(CGPoint)position preview:(CGSize)preview error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  NSError *lockError;
  if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [_captureDevice isFocusPointOfInterestSupported]) {
    if ([_captureDevice lockForConfiguration:&lockError]) {
      if (lockError != nil) {
        *error = [FlutterError errorWithCode:@"FOCUS_ERROR" message:@"impossible to set focus point" details:@""];
        return;
      }
      
      [_captureDevice setFocusPointOfInterest:position];
      [_captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
      
      [_captureDevice unlockForConfiguration];
    }
  }
}

- (void)receivedImageFromStream {
  [self.imageStreamController receivedImageFromStream];
}

/// Get the first available camera on device (front or rear)
- (NSString *)selectAvailableCamera:(CameraSensor)sensor {
  if (_captureDeviceId != nil) {
    return _captureDeviceId;
  }
  
  // TODO: add dual & triple camera
  NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
  AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                       discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera, ]
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
    PigeonSensorType type;
    if (device.deviceType == AVCaptureDeviceTypeBuiltInTelephotoCamera) {
      type = PigeonSensorTypeTelephoto;
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInUltraWideCamera) {
      type = PigeonSensorTypeUltraWideAngle;
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInTrueDepthCamera) {
      type = PigeonSensorTypeTrueDepth;
    } else if (device.deviceType == AVCaptureDeviceTypeBuiltInWideAngleCamera) {
      type = PigeonSensorTypeWideAngle;
    } else {
      type = PigeonSensorTypeUnknown;
    }
    
    PigeonSensorTypeDevice *sensorType = [PigeonSensorTypeDevice makeWithSensorType:type name:device.localizedName iso:[NSNumber numberWithFloat:device.ISO] flashAvailable:[NSNumber numberWithBool:device.flashAvailable] uid:device.uniqueID];
    
    if (device.position == position) {
      [sensors addObject:sensorType];
    }
  }
  
  return sensors;
}

/// Set capture mode between Photo & Video mode
- (void)setCaptureMode:(CaptureModes)captureMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (_videoController.isRecording) {
    *error = [FlutterError errorWithCode:@"CAPTURE_MODE" message:@"impossible to change capture mode, video already recording" details:@""];
    return;
  }
  
  _captureMode = captureMode;
  
  if (captureMode == Video) {
    [self setUpCaptureSessionForAudioError:^(NSError *audioError) {
      *error = [FlutterError errorWithCode:@"VIDEO_ERROR" message:@"error when trying to setup audio" details:[audioError localizedDescription]];
    }];
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
- (void)takePictureAtPath:(NSString *)path completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
  // Instanciate camera picture obj
  CameraPictureController *cameraPicture = [[CameraPictureController alloc] initWithPath:path
                                                                             orientation:_motionController.deviceOrientation
                                                                                  sensor:_cameraSensor
                                                                         saveGPSLocation:_saveGPSLocation
                                                                       mirrorFrontCamera:_mirrorFrontCamera
                                                                             aspectRatio:_aspectRatio
                                                                              completion:completion
                                                                                callback:^{
    // If flash mode is always on, restore it back after photo is taken
    if (self->_torchMode == AVCaptureTorchModeOn) {
      [self->_captureDevice lockForConfiguration:nil];
      [self->_captureDevice setTorchMode:AVCaptureTorchModeOn];
      [self->_captureDevice unlockForConfiguration];
    }
    
    completion(@(YES), nil);
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
- (void)recordVideoAtPath:(NSString *)path withOptions:(VideoOptions *)options completion:(nonnull void (^)(FlutterError * _Nullable))completion {
  if (_imageStreamController.streamImages) {
    completion([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"can't record video when image stream is enabled" details:@""]);
    return;
  }
  
  if (!_videoController.isRecording) {
    [_videoController recordVideoAtPath:path orientation:_deviceOrientation audioSetupCallback:^{
      [self setUpCaptureSessionForAudioError:^(NSError *error) {
        completion([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"error when trying to setup audio" details:[error localizedDescription]]);
      }];
    } videoWriterCallback:^{
      if (self->_videoController.isAudioEnabled) {
        [self->_audioOutput setSampleBufferDelegate:self queue:self->_dispatchQueue];
      }
      [self->_captureVideoOutput setSampleBufferDelegate:self queue:self->_dispatchQueue];
      
      completion(nil);
    } options:options completion:completion];
  } else {
    completion([FlutterError errorWithCode:@"VIDEO_ERROR" message:@"already recording video" details:@""]);
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
- (void)stopRecordingVideo:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
  if (_videoController.isRecording) {
    [_videoController stopRecordingVideo:completion];
  } else {
    completion(@(NO), [FlutterError errorWithCode:@"VIDEO_ERROR" message:@"video is not recording" details:@""]);
  }
}

/// Set audio recording mode
- (void)setRecordingAudioMode:(bool)isAudioEnabled completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
  if (_videoController.isRecording) {
    completion(@(NO), [FlutterError errorWithCode:@"CHANGE_AUDIO_MODE" message:@"impossible to change audio mode, video already recording" details:@""]);
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
    [self setUpCaptureSessionForAudioError:^(NSError *error) {
      completion(@(NO), [FlutterError errorWithCode:@"VIDEO_ERROR" message:@"error when trying to setup audio" details:[error localizedDescription]]);
    }];
  }
  
  
  [_captureSession commitConfiguration];
}

# pragma mark - Audio
/// Setup audio channel to record audio
- (void)setUpCaptureSessionForAudioError:(nonnull void (^)(NSError *))error {
  NSError *audioError = nil;
  // Create a device input with the device and add it to the session.
  // Setup the audio input.
  AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                                           error:&audioError];
  if (audioError) {
    error(audioError);
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
