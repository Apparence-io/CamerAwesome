#import "CamerawesomePlugin.h"
#import "CameraPreview.h"
#import "Pigeon/Pigeon.h"
#import "Permissions.h"
#import "AnalysisController.h"

FlutterEventSink orientationEventSink;
FlutterEventSink videoRecordingEventSink;
FlutterEventSink imageStreamEventSink;
FlutterEventSink physicalButtonEventSink;

@interface CamerawesomePlugin () <CameraInterface, AnalysisImageUtils>
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry> *registry;
@property int64_t textureId;
@property CameraPreview *camera;
- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar;
@end

@implementation CamerawesomePlugin {
  dispatch_queue_t _dispatchQueue;
  dispatch_queue_t _dispatchQueueAnalysis;
}

- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar {
  self = [super init];
  
  _registry = registrar.textures;
  
  if (_dispatchQueue == nil) {
    _dispatchQueue = dispatch_queue_create("camerawesome.dispatchqueue", NULL);
  }
  
  if (_dispatchQueueAnalysis == nil) {
    _dispatchQueueAnalysis = dispatch_queue_create("camerawesome.dispatchqueue.analysis", NULL);
  }
  
  return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  CamerawesomePlugin *instance = [[CamerawesomePlugin alloc] init:registrar];
  FlutterEventChannel *orientationChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/orientation"
                                                                      binaryMessenger:[registrar messenger]];
  FlutterEventChannel *imageStreamChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/images"
                                                                      binaryMessenger:[registrar messenger]];
  FlutterEventChannel *physicalButtonChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/physical_button"
                                                                         binaryMessenger:[registrar messenger]];
  [orientationChannel setStreamHandler:instance];
  [imageStreamChannel setStreamHandler:instance];
  [physicalButtonChannel setStreamHandler:instance];
  
  CameraInterfaceSetup(registrar.messenger, instance);
  AnalysisImageUtilsSetup(registrar.messenger, instance);
}

- (FlutterError *)onListenWithArguments:(NSString *)arguments eventSink:(FlutterEventSink)eventSink {
  if ([arguments  isEqual: @"orientationChannel"]) {
    orientationEventSink = eventSink;
    
    if (self.camera != nil) {
      [self.camera setOrientationEventSink:orientationEventSink];
    }
    
  } else if ([arguments  isEqual: @"imagesChannel"]) {
    imageStreamEventSink = eventSink;
    
    if (self.camera != nil) {
      [self.camera setImageStreamEvent:imageStreamEventSink];
    }
  } else if ([arguments  isEqual: @"physicalButtonChannel"]) {
    physicalButtonEventSink = eventSink;
    
    if (self.camera != nil) {
      [self.camera setPhysicalButtonEventSink:physicalButtonEventSink];
    }
  }
  
  return nil;
}

- (FlutterError *)onCancelWithArguments:(NSString *)arguments {
  if ([arguments  isEqual: @"orientationChannel"]) {
    orientationEventSink = nil;
    
    if (self.camera != nil && self.camera.motionController != nil) {
      [self.camera setOrientationEventSink:orientationEventSink];
    }
  } else if ([arguments  isEqual: @"imagesChannel"]) {
    imageStreamEventSink = nil;
    
    if (self.camera != nil) {
      [self.camera setImageStreamEvent:imageStreamEventSink];
    }
  } else if ([arguments  isEqual: @"physicalButtonChannel"]) {
    physicalButtonEventSink = nil;
    
    if (self.camera != nil) {
      [self.camera setPhysicalButtonEventSink:physicalButtonEventSink];
    }
  }
  return nil;
}

- (nullable NSArray<PreviewSize *> *)availableSizesWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return [CameraQualities captureFormatsForDevice:_camera.captureDevice];
}

- (nullable NSArray<NSString *> *)checkPermissionsWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  NSMutableArray *permissions = [NSMutableArray new];
  
  bool cameraPermission = [CameraPermissionsController checkPermission];
  bool microphonePermission = [MicrophonePermissionsController checkPermission];
  
  if (cameraPermission) {
    [permissions addObject:@"camera"];
  }
  
  if (microphonePermission) {
    [permissions addObject:@"record_audio"];
  }
  
  return permissions;
}

- (void)focusOnPointPreviewSize:(nonnull PreviewSize *)previewSize x:(nonnull NSNumber *)x y:(nonnull NSNumber *)y androidFocusSettings:(nullable AndroidFocusSettings *)androidFocusSettings error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  if (previewSize.width <= 0 || previewSize.height <= 0) {
    *error = [FlutterError errorWithCode:@"INVALID_PREVIEW" message:@"preview size width and height must be set" details:nil];
    return;
  }
  
  [_camera focusOnPoint:CGPointMake([x floatValue], [y floatValue]) preview:CGSizeMake([previewSize.width floatValue], [previewSize.height floatValue]) error:error];
}

- (nullable PreviewSize *)getEffectivPreviewSizeWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  CGSize previewSize = [_camera getEffectivPreviewSize];
  
  // height & width are inverted, this is intentionnal, because camera is always on portrait mode
  return [PreviewSize makeWithWidth:@(previewSize.height) height:@(previewSize.width)];
}

- (nullable NSNumber *)getMaxZoomWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return @([_camera getMaxZoom]);
}

- (nullable NSNumber *)getPreviewTextureIdWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return @(_textureId);
}

- (void)handleAutoFocusWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  // TODO: to remove ?
}

- (void)pauseVideoRecordingWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [self.camera pauseVideoRecording];
}

- (void)recordVideoPath:(nonnull NSString *)path options:(nullable VideoOptions *)options completion:(nonnull void (^)(FlutterError * _Nullable))completion {
  if (path == nil || path.length <= 0) {
    completion([FlutterError errorWithCode:@"PATH_NOT_SET" message:@"a file path must be set" details:nil]);
    return;
  }
  
  [_camera recordVideoAtPath:path withOptions:options completion:completion];
}

- (void)refreshWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_camera refresh];
}

- (nullable NSArray<NSString *> *)requestPermissionsWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return @[];
}

- (void)resumeVideoRecordingWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [self.camera resumeVideoRecording];
}

- (void)setAspectRatioAspectRatio:(nonnull NSString *)aspectRatio error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (aspectRatio == nil || aspectRatio.length <= 0) {
    *error = [FlutterError errorWithCode:@"RATIO_NOT_SET" message:@"a ratio must be set" details:nil];
    return;
  }
  
  AspectRatio aspectRatioMode = [self convertAspectRatio:aspectRatio];
  [self.camera setAspectRatio:aspectRatioMode];
}

- (void)setCaptureModeMode:(nonnull NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  CaptureModes captureMode = ([mode isEqualToString:@"PHOTO"]) ? Photo : Video;
  [_camera setCaptureMode:captureMode error:error];
}

- (void)setCorrectionBrightness:(nonnull NSNumber *)brightness error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_camera setBrightness:brightness error:error];
}
- (void)setExifPreferencesExifPreferences:(ExifPreferences *)exifPreferences completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion{
  [self.camera setExifPreferencesGPSLocation: exifPreferences.saveGPSLocation completion:completion];
}

- (void)setFlashModeMode:(nonnull NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (mode == nil || mode.length <= 0) {
    *error = [FlutterError errorWithCode:@"FLASH_MODE_ERROR" message:@"a flash mode NONE, AUTO, ALWAYS must be provided" details:nil];
    return;
  }
  
  CameraFlashMode flash;
  if ([mode isEqualToString:@"NONE"]) {
    flash = None;
  } else if ([mode isEqualToString:@"ON"]) {
    flash = On;
  } else if ([mode isEqualToString:@"AUTO"]) {
    flash = Auto;
  } else if ([mode isEqualToString:@"ALWAYS"]) {
    flash = Always;
  } else {
    flash = None;
  }
  
  [_camera setFlashMode:flash error:error];
}

- (void)setPhotoSizeSize:(nonnull PreviewSize *)size error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (size.width <= 0 || size.height <= 0) {
    *error = [FlutterError errorWithCode:@"NO_SIZE_SET" message:@"width and height must be set" details:nil];
    return;
  }
  
  if (self.camera == nil) {
    *error = [FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil];
    return;
  }
  
  [self.camera setCameraPresset:CGSizeMake([size.width floatValue], [size.height floatValue])];
}

- (void)setPreviewSizeSize:(nonnull PreviewSize *)size error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (size.width <= 0 || size.height <= 0) {
    *error = [FlutterError errorWithCode:@"NO_SIZE_SET" message:@"width and height must be set" details:nil];
    return;
  }
  
  if (self.camera == nil) {
    *error = [FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil];
    return;
  }
  
  [self.camera setPreviewSize:CGSizeMake([size.width floatValue], [size.height floatValue]) error:error];
}

- (void)setRecordingAudioModeEnableAudio:(NSNumber *)enableAudio completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion {
  [_camera setRecordingAudioMode:[enableAudio boolValue] completion:completion];
}

- (void)setSensorSensor:(NSString *)sensor deviceId:(nullable NSString *)deviceId error:(FlutterError *_Nullable *_Nonnull)error {
  NSString *captureDeviceId;
  
  if (deviceId && ![deviceId isEqual:[NSNull null]]) {
    captureDeviceId = deviceId;
  }
  
  CameraSensor sensorType = ([sensor isEqualToString:@"FRONT"]) ? Front : Back;
  [_camera setSensor:sensorType deviceId:captureDeviceId];
}

- (void)setZoomZoom:(nonnull NSNumber *)zoom error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_camera setZoom:[zoom floatValue] error:error];
}

- (void)receivedImageFromStreamWithError:(FlutterError *_Nullable *_Nonnull)error {
  [self.camera receivedImageFromStream];
}

- (nullable NSArray<PigeonSensorTypeDevice *> *)getFrontSensorsWithError:(FlutterError *_Nullable *_Nonnull)error {
  return [_camera getSensors:AVCaptureDevicePositionFront];
}

- (nullable NSArray<PigeonSensorTypeDevice *> *)getBackSensorsWithError:(FlutterError *_Nullable *_Nonnull)error {
  return [_camera getSensors:AVCaptureDevicePositionBack];
}

- (void)setupCameraSensor:(nonnull NSString *)sensor aspectRatio:(nonnull NSString *)aspectRatio zoom:(nonnull NSNumber *)zoom mirrorFrontCamera:(nonnull NSNumber *)mirrorFrontCamera enablePhysicalButton:(nonnull NSNumber *)enablePhysicalButton flashMode:(nonnull NSString *)flashMode captureMode:(nonnull NSString *)captureMode enableImageStream:(nonnull NSNumber *)enableImageStream exifPreferences:(nonnull ExifPreferences *)exifPreferences completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
  if (![CameraPermissionsController checkAndRequestPermission]) {
    completion(nil, [FlutterError errorWithCode:@"MISSING_PERMISSION" message:@"you got to accept all permissions" details:nil]);
    return;
  }
  
  if (sensor == nil || sensor.length <= 0) {
    completion(nil, [FlutterError errorWithCode:@"SENSOR_ERROR" message:@"a sensor FRONT or BACK must be provided" details:nil]);
    return;
  }
  
  // If camera preview exist, dispose it
  if (self.camera != nil) {
    [self.camera dispose];
    self.camera = nil;
  }
  
  AspectRatio aspectRatioMode = [self convertAspectRatio:aspectRatio];
  CaptureModes captureModeType = ([captureMode isEqualToString:@"PHOTO"]) ? Photo : Video;
  CameraSensor cameraSensor = ([sensor isEqualToString:@"FRONT"]) ? Front : Back;
  self.camera = [[CameraPreview alloc] initWithCameraSensor:cameraSensor
                                               streamImages:[enableImageStream boolValue]
                                          mirrorFrontCamera:[mirrorFrontCamera boolValue]
                                       enablePhysicalButton:[enablePhysicalButton boolValue]
                                            aspectRatioMode:aspectRatioMode
                                                captureMode:captureModeType
                                                 completion:completion
                                              dispatchQueue:dispatch_queue_create("camerawesome.dispatchqueue", NULL)];
  [self->_registry textureFrameAvailable:self->_textureId];
  
  __weak typeof(self) weakSelf = self;
  self.camera.onFrameAvailable = ^{
    [weakSelf.registry textureFrameAvailable:weakSelf.textureId];
  };
  
  // Assign texture id
  self->_textureId = [self->_registry registerTexture:self.camera];
  
  completion(@(YES), nil);
}

- (void)setupImageAnalysisStreamFormat:(nonnull NSString *)format width:(nonnull NSNumber *)width maxFramesPerSecond:(nullable NSNumber *)maxFramesPerSecond autoStart:(nonnull NSNumber *)autoStart error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_camera.imageStreamController setStreamImages:autoStart];
  
  // Force a frame rate to improve performance
  [_camera.imageStreamController setMaxFramesPerSecond:[maxFramesPerSecond floatValue]];
}

- (nullable NSNumber *)startWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (self.camera == nil) {
    *error = [FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil];
    return @(NO);
  }
  
  dispatch_async(_dispatchQueue, ^{
    [self->_camera start];
  });
  
  return @(YES);
}

- (void)stopRecordingVideoWithCompletion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
  dispatch_async(_dispatchQueue, ^{
    [self->_camera stopRecordingVideo:completion];
  });
}

- (nullable NSNumber *)stopWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (self.camera == nil) {
    *error = [FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil];
    return @(NO);
  }
  
  dispatch_async(_dispatchQueue, ^{
    [self->_registry unregisterTexture:self->_textureId]; // Lets try this
    [self->_camera stop];
  });
  
  return @(YES);
}

- (void)takePhotoPath:(nonnull NSString *)path completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
  if (path == nil || path.length <= 0) {
    completion(nil, [FlutterError errorWithCode:@"PATH_NOT_SET" message:@"a file path must be set" details:nil]);
    return;
  }
  
  dispatch_async(_dispatchQueue, ^{
    [self->_camera takePictureAtPath:path completion:completion];
  });
}

- (void)requestPermissionsSaveGpsLocation:(nonnull NSNumber *)saveGpsLocation completion:(nonnull void (^)(NSArray<NSString *> * _Nullable, FlutterError * _Nullable))completion {
  NSMutableArray *permissions = [NSMutableArray new];
  
  const Boolean cameraGranted = [CameraPermissionsController checkAndRequestPermission];
  if (cameraGranted) {
    [permissions addObject:@"camera"];
  }
  
  bool needToSaveGPSLocation = [saveGpsLocation boolValue];
  if (needToSaveGPSLocation) {
    // TODO: move this to permissions object
    [self.camera.locationController requestWhenInUseAuthorizationOnGranted:^{
      [permissions addObject:@"location"];
      
      completion(permissions, nil);
    } declined:^{
      completion(permissions, nil);
    }];
  }
}


- (void)startAnalysisWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (self.camera.videoController.isRecording) {
    *error = [FlutterError errorWithCode:@"VIDEO_ERROR" message:@"can't start image stream because video is recording" details:@""];
    return;
  }
  
  [self.camera.imageStreamController setStreamImages:true];
}


- (void)stopAnalysisWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [self.camera.imageStreamController setStreamImages:false];
}


- (void)setFilterMatrix:(NSArray<NSNumber *> *)matrix error:(FlutterError *_Nullable *_Nonnull)error {
  // TODO: try to use CIFilter when taking a picture
}

- (void)setMirrorFrontCameraMirror:(nonnull NSNumber *)mirror error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_camera setMirrorFrontCamera:[mirror boolValue] error:error];
}

- (AspectRatio)convertAspectRatio:(NSString *)aspectRatioStr {
  AspectRatio aspectRatioMode;
  if ([aspectRatioStr isEqualToString:@"RATIO_4_3"]) {
    aspectRatioMode = Ratio4_3;
  } else if ([aspectRatioStr isEqualToString:@"RATIO_16_9"]) {
    aspectRatioMode = Ratio16_9;
  } else {
    aspectRatioMode = Ratio1_1;
  }
  return aspectRatioMode;
}

- (void)isVideoRecordingAndImageAnalysisSupportedSensor:(NSString *)sensor completion:(void (^)(NSNumber *_Nullable, FlutterError *_Nullable))completion{
  completion(@(YES), nil);
}

- (void)bgra8888toJpegBgra8888image:(nonnull AnalysisImageWrapper *)bgra8888image jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  dispatch_async(_dispatchQueueAnalysis, ^{
    [AnalysisController bgra8888toJpegBgra8888image:bgra8888image jpegQuality:jpegQuality completion:completion];
  });
}

- (void)nv21toJpegNv21Image:(nonnull AnalysisImageWrapper *)nv21Image jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  [AnalysisController nv21toJpegNv21Image:nv21Image jpegQuality:jpegQuality completion:completion];
}

- (void)yuv420toJpegYuvImage:(nonnull AnalysisImageWrapper *)yuvImage jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  [AnalysisController yuv420toJpegYuvImage:yuvImage jpegQuality:jpegQuality completion:completion];
}

- (void)yuv420toNv21YuvImage:(nonnull AnalysisImageWrapper *)yuvImage completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  [AnalysisController yuv420toNv21YuvImage:yuvImage completion:completion];
}

@end
