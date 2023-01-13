#import "CamerawesomePlugin.h"
#import "CameraPreview.h"
#import "Pigeon/Pigeon.h"

FlutterEventSink orientationEventSink;
FlutterEventSink videoRecordingEventSink;
FlutterEventSink imageStreamEventSink;

//@interface CamerawesomePlugin ()
//
//@property(readonly, nonatomic) NSObject<FlutterTextureRegistry> *registry;
//@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
//@property int64_t textureId;
//@property CameraPreview *camera;
//
//- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry> *)registry messenger:(NSObject<FlutterBinaryMessenger> *)messenger;
//
//@end

@interface CamerawesomePlugin () <CameraInterface>
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry> *registry;
@property int64_t textureId;
@property CameraPreview *camera;

- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar;

@end


@implementation CamerawesomePlugin {
  dispatch_queue_t _dispatchQueue;
}

- (instancetype)init:(NSObject<FlutterPluginRegistrar>*)registrar {
  self = [super init];
  
  _registry = registrar.textures;
  
  if (_dispatchQueue == nil) {
    _dispatchQueue = dispatch_queue_create("camerawesome.dispatchqueue", NULL);
  }
  
  return self;
}

//- (id)init {
//  if ( self = [super init] ) {
//    if (_dispatchQueue == nil) {
//      _dispatchQueue = dispatch_queue_create("camerawesome.dispatchqueue", NULL);
//    }
//  }
//  return self;
//}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  CamerawesomePlugin *instance = [[CamerawesomePlugin alloc] init:registrar];
  FlutterEventChannel *orientationChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/orientation"
                                                                      binaryMessenger:[registrar messenger]];
  FlutterEventChannel *imageStreamChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/images"
                                                                      binaryMessenger:[registrar messenger]];
  [orientationChannel setStreamHandler:instance];
  [imageStreamChannel setStreamHandler:instance];
  
  CameraInterfaceSetup(registrar.messenger, instance);
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
  }
  return nil;
}

- (nullable NSArray<PreviewSize *> *)availableSizesWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  return [CameraQualities captureFormatsForDevice:_camera.captureDevice];
}

- (nullable NSArray<NSString *> *)checkPermissionsWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  bool cameraPermission = [PermissionsController checkCameraPermission];
  if (cameraPermission) {
    return @[];
  } else {
    return @[@"camera"];
  }
}

- (void)focusOnPointPreviewSize:(nonnull PreviewSize *)previewSize x:(nonnull NSNumber *)x y:(nonnull NSNumber *)y error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  if (previewSize.width <= 0 || previewSize.height <= 0) {
    *error = [FlutterError errorWithCode:@"INVALID_PREVIEW" message:@"preview size width and height must be set" details:nil];
    return;
  }
  
  [_camera focusOnPoint:CGPointMake([x floatValue], [y floatValue]) preview:CGSizeMake([previewSize.width floatValue], [previewSize.height floatValue])];
}

//- (void)focusWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
//  // TODO
//}

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
  // TODO
}

- (void)pauseVideoRecordingWithError:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [self.camera pauseVideoRecording];
}

- (void)recordVideoPath:(NSString *)path options:(nullable VideoOptions *)options error:(FlutterError *_Nullable *_Nonnull)error {
  if (path == nil || path.length <= 0) {
    *error = [FlutterError errorWithCode:@"PATH_NOT_SET" message:@"a file path must be set" details:nil];
    return;
  }
  
  [_camera recordVideoAtPath:path withOptions:options error:error];
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
  
  AspectRatio aspectRatioMode;
  if ([aspectRatio isEqualToString:@"RATIO_4_3"]) {
    aspectRatioMode = Ratio4_3;
  } else if ([aspectRatio isEqualToString:@"RATIO_16_9"]) {
    aspectRatioMode = Ratio16_9;
  } else {
    aspectRatioMode = Ratio1_1;
  }
  
  [self.camera setAspectRatio:aspectRatioMode];
}

- (void)setCaptureModeMode:(nonnull NSString *)mode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  CaptureModes captureMode = ([mode isEqualToString:@"PHOTO"]) ? Photo : Video;
  [_camera setCaptureMode:captureMode];
}

- (void)setCorrectionBrightness:(nonnull NSNumber *)brightness error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  // TODO
}

- (void)setExifPreferencesExifPreferences:(nonnull ExifPreferences *)exifPreferences error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [self.camera setExifPreferencesGPSLocation: exifPreferences.saveGPSLocation];
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
  
  [_camera setFlashMode:flash];
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
  
  [self.camera setPreviewSize:CGSizeMake([size.width floatValue], [size.height floatValue])];
}

- (void)setRecordingAudioModeEnableAudio:(nonnull NSNumber *)enableAudio error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  [_camera setRecordingAudioMode:[enableAudio boolValue]];
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
  [_camera setZoom:[zoom floatValue]];
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

- (void)setupCameraSensor:(nonnull NSString *)sensor aspectRatio:(nonnull NSString *)aspectRatio zoom:(nonnull NSNumber *)zoom flashMode:(nonnull NSString *)flashMode captureMode:(nonnull NSString *)captureMode enableImageStream:(nonnull NSNumber *)enableImageStream exifPreferences:(nonnull ExifPreferences *)exifPreferences completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
  //  NSString *sensorName = call.arguments[@"sensor"];
  //  NSString *captureModeName = call.arguments[@"captureMode"];
  //  BOOL streamImages = [call.arguments[@"streamImages"] boolValue];
  //dispatch_async(_dispatchQueue, ^{
    if (![PermissionsController checkCameraPermission]) {
      completion(nil, [FlutterError errorWithCode:@"MISSING_PERMISSION" message:@"you got to accept all permissions" details:nil]);
      return;
    }
    
    if (sensor == nil || sensor.length <= 0) {
      completion(nil, [FlutterError errorWithCode:@"SENSOR_ERROR" message:@"a sensor FRONT or BACK must be provided" details:nil]);
      return;
    }
    
    CaptureModes captureModeType = ([captureMode isEqualToString:@"PHOTO"]) ? Photo : Video;
    CameraSensor cameraSensor = ([sensor isEqualToString:@"FRONT"]) ? Front : Back;
    self.camera = [[CameraPreview alloc] initWithCameraSensor:cameraSensor
                                                 streamImages:[enableImageStream boolValue]
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
    //  result(@(YES));
  //});
}

- (void)setupImageAnalysisStreamFormat:(nonnull NSString *)format width:(nonnull NSNumber *)width maxFramesPerSecond:(nullable NSNumber *)maxFramesPerSecond error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  
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

@end




//@implementation CamerawesomePlugin {
//  dispatch_queue_t _dispatchQueue;
//}
//- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry> *)registry
//                       messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
//  self = [super init];
//  NSAssert(self, @"super init cannot be nil");
//  _registry = registry;
//  _messenger = messenger;
//
//  return self;
//}
//
//+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
//  CamerawesomePlugin *instance = [[CamerawesomePlugin alloc] initWithRegistry:[registrar textures] messenger:[registrar messenger]];
//
//  FlutterEventChannel *orientationChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/orientation"
//                                                                      binaryMessenger:[registrar messenger]];
//  FlutterEventChannel *imageStreamChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/images"
//                                                                      binaryMessenger:[registrar messenger]];
//  [orientationChannel setStreamHandler:instance];
//  [imageStreamChannel setStreamHandler:instance];
//
//  FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:@"camerawesome" binaryMessenger:[registrar messenger]];
//  [registrar addMethodCallDelegate:instance channel:methodChannel];
//}
//
//- (FlutterError *)onListenWithArguments:(NSString *)arguments eventSink:(FlutterEventSink)eventSink {
//  if ([arguments  isEqual: @"orientationChannel"]) {
//    orientationEventSink = eventSink;
//
//    if (self.camera != nil) {
//      [self.camera setOrientationEventSink:orientationEventSink];
//    }
//
//  } else if ([arguments  isEqual: @"imagesChannel"]) {
//    imageStreamEventSink = eventSink;
//
//    if (self.camera != nil) {
//      [self.camera setImageStreamEvent:imageStreamEventSink];
//    }
//  }
//
//  return nil;
//}
//
//- (FlutterError *)onCancelWithArguments:(NSString *)arguments {
//  if ([arguments  isEqual: @"orientationChannel"]) {
//    orientationEventSink = nil;
//
//    if (self.camera != nil && self.camera.motionController != nil) {
//      [self.camera setOrientationEventSink:orientationEventSink];
//    }
//  } else if ([arguments  isEqual: @"imagesChannel"]) {
//    imageStreamEventSink = nil;
//
//    if (self.camera != nil) {
//      [self.camera setImageStreamEvent:imageStreamEventSink];
//    }
//  }
//  return nil;
//}
//
//- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
//  if (_dispatchQueue == nil) {
//    _dispatchQueue = dispatch_queue_create("camerawesome.dispatchqueue", NULL);
//  }
//  [_camera setResult:result];
//
//  dispatch_async(_dispatchQueue, ^{
//    [self handleMethodCallAsync:call result:result];
//  });
//}
//
//- (void)handleMethodCallAsync:(FlutterMethodCall *)call result:(FlutterResult)result {
//  if ([@"init" isEqualToString:call.method]) {
//    [self _handleSetup:call result:result];
//  } else if ([@"checkPermissions" isEqualToString:call.method]) {
//    [self _handleCheckPermissions:call result:result];
//  } else if ([@"start" isEqualToString:call.method]) {
//    [self _handleStart:call result:result];
//  } else if ([@"stop" isEqualToString:call.method]) {
//    [self _handleStop:call result:result];
//  } else if ([@"refresh" isEqualToString:call.method]) {
//    [self _handleRefresh:call result:result];
//  } else if ([@"availableSizes" isEqualToString:call.method]) {
//    [self _handleSizes:call result:result];
//  } else if ([@"previewTexture" isEqualToString:call.method]) {
//    [self _handleGetTextures:call result:result];
//  } else if ([@"setPreviewSize" isEqualToString:call.method]) {
//    [self _handlePreviewSize:call result:result];
//  } else if ([@"getEffectivPreviewSize" isEqualToString:call.method]) {
//    [self _handleGetEffectivPreviewSize:call result:result];
//  } else if ([@"setPhotoSize" isEqualToString:call.method]) {
//    [self _handlePhotoSize:call result:result];
//  } else if ([@"takePhoto" isEqualToString:call.method]) {
//    [self _handleTakePhoto:call result:result];
//  } else if ([@"recordVideo" isEqualToString:call.method]) {
//    [self _handleRecordVideo:call result:result];
//  } else if ([@"pauseVideoRecording" isEqualToString:call.method]) {
//    [self _handlePauseVideoRecording:call result:result];
//  } else if ([@"resumeVideoRecording" isEqualToString:call.method]) {
//    [self _handleResumeVideoRecording:call result:result];
//  } else if ([@"stopRecordingVideo" isEqualToString:call.method]) {
//    [self _handleStopRecordingVideo:call result:result];
//  } else if ([@"setRecordingAudioMode" isEqualToString:call.method]) {
//    [self _handleRecordingAudioMode:call result:result];
//  } else if ([@"focusOnPoint" isEqualToString:call.method]) {
//    [self _handleFocusOnPoint:call result:result];
//  } else if ([@"setFlashMode" isEqualToString:call.method]) {
//    [self _handleFlashMode:call result:result];
//  } else if ([@"setAspectRatio" isEqualToString:call.method]) {
//    [self _handleSetAspectRatio:call result:result];
//  } else if ([@"setSensor" isEqualToString:call.method]) {
//    [self _handleSetSensor:call result:result];
//  } else if ([@"setCaptureMode" isEqualToString:call.method]) {
//    [self _handleSetCaptureMode:call result:result];
//  } else if ([@"setZoom" isEqualToString:call.method]) {
//    [self _handleSetZoom:call result:result];
//  } else if ([@"getMaxZoom" isEqualToString:call.method]) {
//    [self _handleGetMaxZoom:call result:result];
//  } else if ([@"setExifPreferences" isEqualToString:call.method]) {
//    [self _handleSetExifPreferences:call result:result];
//  } else if ([@"setupAnalysis" isEqualToString:call.method]) {
//    [self _handleSetupAnalysis:call result:result];
//  } else if ([@"receivedImageFromStream" isEqualToString:call.method]) {
//    [self _handleReceivedImageFromStream:call result:result];
//  } else if ([@"getSensors" isEqualToString:call.method]) {
//    [self _handleGetSensors:call result:result];
//  } else if ([@"dispose" isEqualToString:call.method]) {
//    [self _handleDispose:call result:result];
//  } else {
//    result(FlutterMethodNotImplemented);
//    return;
//  };
//}
//
//- (void)_handleSetAspectRatio:(FlutterMethodCall*)call result:(FlutterResult)result {
//  NSString *ratioArg = call.arguments[@"ratio"];
//
//  if (ratioArg == nil || ratioArg.length <= 0) {
//    result([FlutterError errorWithCode:@"RATIO_NOT_SET" message:@"a ratio must be set" details:nil]);
//    return;
//  }
//
//  AspectRatio aspectRatio;
//  if ([ratioArg isEqualToString:@"RATIO_4_3"]) {
//    aspectRatio = Ratio4_3;
//  } else if ([ratioArg isEqualToString:@"RATIO_16_9"]) {
//    aspectRatio = Ratio16_9;
//  } else {
//    aspectRatio = Ratio1_1;
//  }
//
//  [self.camera setAspectRatio:aspectRatio];
//  result(nil);
//}
//
//- (void)_handlePauseVideoRecording:(FlutterMethodCall*)call result:(FlutterResult)result {
//  [self.camera pauseVideoRecording];
//}
//
//- (void)_handleReceivedImageFromStream:(FlutterMethodCall*)call result:(FlutterResult)result {
//  [self.camera receivedImageFromStream];
//}
//
//- (void)_handleResumeVideoRecording:(FlutterMethodCall*)call result:(FlutterResult)result {
//  [self.camera resumeVideoRecording];
//}
//
//- (void)_handleRecordingAudioMode:(FlutterMethodCall*)call result:(FlutterResult)result {
//  bool value = [call.arguments[@"enableAudio"] boolValue];
//  [_camera setRecordingAudioMode:value];
//}
//
//- (void)_handleSetupAnalysis:(FlutterMethodCall*)call result:(FlutterResult)result {
//  float maxFramesPerSecond = [call.arguments[@"maxFramesPerSecond"] floatValue];
//
//  // Force a frame rate to improve performance
//  [_camera.imageStreamController setMaxFramesPerSecond:maxFramesPerSecond];
//
//  result(nil);
//}
//
//- (void)_handleGetSensors:(FlutterMethodCall*)call result:(FlutterResult)result {
//  NSArray *frontSensors = [_camera getSensors:AVCaptureDevicePositionFront];
//  NSArray *backSensors = [_camera getSensors:AVCaptureDevicePositionBack];
//
//  result(@{
//    @"front": frontSensors,
//    @"back": backSensors
//  });
//}
//
//- (void)_handleGetEffectivPreviewSize:(FlutterMethodCall*)call result:(FlutterResult)result {
//  CGSize previewSize = [_camera getEffectivPreviewSize];
//  // height & width are inverted, this is intentionnal, because camera is always on portrait mode
//  result(@{
//    @"width": [NSNumber numberWithInt:previewSize.height],
//    @"height": [NSNumber numberWithInt:previewSize.width],
//  });
//}
//
//- (void)_handleSetZoom:(FlutterMethodCall*)call result:(FlutterResult)result {
//  float value = [call.arguments[@"zoom"] floatValue];
//  [_camera setZoom:value];
//}
//
//- (NSInteger)_handleGetMaxZoom:(FlutterMethodCall*)call result:(FlutterResult)result {
//  return [_camera getMaxZoom];
//}
//
//- (void)_handleDispose:(FlutterMethodCall*)call result:(FlutterResult)result {
//  [_camera dispose];
//  _dispatchQueue = nil;
//  result(nil);
//}
//
//- (void)_handleTakePhoto:(FlutterMethodCall*)call result:(FlutterResult)result {
//  NSString *path = call.arguments[@"path"];
//
//  if (path == nil || path.length <= 0) {
//    result([FlutterError errorWithCode:@"PATH_NOT_SET" message:@"a file path must be set" details:nil]);
//    return;
//  }
//
//  [_camera takePictureAtPath:path];
//}
//
//- (void)_handleRecordVideo:(FlutterMethodCall*)call result:(FlutterResult)result {
//  NSString *path = call.arguments[@"path"];
//  NSDictionary *options = call.arguments[@"options"];
//
//  if (path == nil || path.length <= 0) {
//    result([FlutterError errorWithCode:@"PATH_NOT_SET" message:@"a file path must be set" details:nil]);
//    return;
//  }
//
//  [_camera recordVideoAtPath:path withOptions:options];
//}
//
//- (void)_handleStopRecordingVideo:(FlutterMethodCall*)call result:(FlutterResult)result {
//  [_camera stopRecordingVideo];
//}
//
//- (void)_handleSetSensor:(FlutterMethodCall*)call result:(FlutterResult)result {
//  NSString *sensorName = call.arguments[@"sensor"];
//  NSString *captureDeviceId;
//
//  if (call.arguments[@"deviceId"] && call.arguments[@"deviceId"] != [NSNull null]) {
//    captureDeviceId = call.arguments[@"deviceId"];
//  }
//
//  CameraSensor sensor = ([sensorName isEqualToString:@"FRONT"]) ? Front : Back;
//  [_camera setSensor:sensor deviceId:captureDeviceId];
//
//  result(nil);
//}
//
//- (void)_handleSetCaptureMode:(FlutterMethodCall*)call result:(FlutterResult)result {
//  NSString *captureModeName = call.arguments[@"captureMode"];
//
//  CaptureModes captureMode = ([captureModeName isEqualToString:@"PHOTO"]) ? Photo : Video;
//  [_camera setCaptureMode:captureMode];
//
//  result(nil);
//}
//
//- (void)_handleFocusOnPoint:(FlutterMethodCall*)call result:(FlutterResult)result {
//  float positionX = [call.arguments[@"positionX"] floatValue];
//  float positionY = [call.arguments[@"positionY"] floatValue];
//
//  float previewWidth = [call.arguments[@"previewWidth"] floatValue];
//  float previewHeight = [call.arguments[@"previewHeight"] floatValue];
//
//  if (previewWidth <= 0 || previewHeight <= 0) {
//    result([FlutterError errorWithCode:@"INVALID_PREVIEW" message:@"preview size width and height must be set" details:nil]);
//    return;
//  }
//
//  [_camera focusOnPoint:CGPointMake(positionX, positionY) preview:CGSizeMake(previewWidth, previewHeight)];
//}
//
//- (void)_handleCheckPermissions:(FlutterMethodCall*)call result:(FlutterResult)result {
//  result(@([PermissionsController checkCameraPermission]));
//}
//
//- (void)_handleSizes:(FlutterMethodCall*)call result:(FlutterResult)result {
//  result([CameraQualities captureFormatsForDevice:_camera.captureDevice]);
//}
//
//- (void)_handlePreviewSize:(FlutterMethodCall*)call result:(FlutterResult)result {
//  float width = [call.arguments[@"width"] floatValue];
//  float height = [call.arguments[@"height"] floatValue];
//
//  if (width <= 0 || height <= 0) {
//    result([FlutterError errorWithCode:@"NO_SIZE_SET" message:@"width and height must be set" details:nil]);
//    return;
//  }
//
//  if (self.camera == nil) {
//    result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
//    return;
//  }
//
//  [self.camera setPreviewSize:CGSizeMake(width, height)];
//
//  result(nil);
//}
//
//- (void)_handlePhotoSize:(FlutterMethodCall*)call result:(FlutterResult)result {
//  float width = [call.arguments[@"width"] floatValue];
//  float height = [call.arguments[@"height"] floatValue];
//
//  if (width <= 0 || height <= 0) {
//    result([FlutterError errorWithCode:@"NO_SIZE_SET" message:@"width and height must be set" details:nil]);
//    return;
//  }
//
//  if (self.camera == nil) {
//    result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
//    return;
//  }
//
//  [self.camera setCameraPresset:CGSizeMake(width, height)];
//
//  result(nil);
//}
//
//- (void)_handleStart:(FlutterMethodCall*)call result:(FlutterResult)result {
//  if (self.camera == nil) {
//    result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
//    return;
//  }
//
//  [_camera start];
//
//  result(@(YES));
//}
//
//- (void)_handleStop:(FlutterMethodCall*)call result:(FlutterResult)result {
//  if (self.camera == nil) {
//    result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
//    return;
//  }
//
//  [_camera stop];
//
//  result(@(YES));
//}
//
//- (void)_handleRefresh:(FlutterMethodCall*)call result:(FlutterResult)result {
//  [_camera refresh];
//}
//
//- (void)_handleSetExifPreferences:(FlutterMethodCall*)call result:(FlutterResult)result  {
//  bool saveGPSLocation = [call.arguments[@"saveGPSLocation"] boolValue];
//
//  [self.camera setExifPreferencesGPSLocation: saveGPSLocation];
//}
//
//- (void)_handleSetup:(FlutterMethodCall*)call result:(FlutterResult)result  {
//  NSString *sensorName = call.arguments[@"sensor"];
//  NSString *captureModeName = call.arguments[@"captureMode"];
//  BOOL streamImages = [call.arguments[@"streamImages"] boolValue];
//
//  CaptureModes captureMode = ([captureModeName isEqualToString:@"PHOTO"]) ? Photo : Video;
//
//  if (![PermissionsController checkCameraPermission]) {
//    result([FlutterError errorWithCode:@"MISSING_PERMISSION" message:@"you got to accept all permissions" details:nil]);
//    return;
//  }
//
//  if (sensorName == nil || sensorName.length <= 0) {
//    result([FlutterError errorWithCode:@"SENSOR_ERROR" message:@"a sensor FRONT or BACK must be provided" details:nil]);
//    return;
//  }
//
//  CameraSensor sensor = ([sensorName isEqualToString:@"FRONT"]) ? Front : Back;
//  self.camera = [[CameraPreview alloc] initWithCameraSensor:sensor
//                                               streamImages:streamImages
//                                                captureMode:captureMode
//                                                     result:result
//                                              dispatchQueue:_dispatchQueue
//                                                  messenger:_messenger];
//  [self->_registry textureFrameAvailable:_textureId];
//
//  __weak typeof(self) weakSelf = self;
//  self.camera.onFrameAvailable = ^{
//    [weakSelf.registry textureFrameAvailable:weakSelf.textureId];
//  };
//
//  // Assign texture id
//  _textureId = [_registry registerTexture:self.camera];
//
//  result(@(YES));
//}
//
//- (void)_handleFlashMode:(FlutterMethodCall*)call result:(FlutterResult)result  {
//  NSString *flashMode = call.arguments[@"mode"];
//
//  if (flashMode == nil || flashMode.length <= 0) {
//    result([FlutterError errorWithCode:@"FLASH_MODE_ERROR" message:@"a flash mode NONE, AUTO, ALWAYS must be provided" details:nil]);
//    return;
//  }
//
//  CameraFlashMode flash;
//  if ([flashMode isEqualToString:@"NONE"]) {
//    flash = None;
//  } else if ([flashMode isEqualToString:@"ON"]) {
//    flash = On;
//  } else if ([flashMode isEqualToString:@"AUTO"]) {
//    flash = Auto;
//  } else if ([flashMode isEqualToString:@"ALWAYS"]) {
//    flash = Always;
//  } else {
//    flash = None;
//  }
//
//  [_camera setFlashMode:flash];
//  result(@(YES));
//}
//
//- (void)_handleGetTextures:(FlutterMethodCall*)call result:(FlutterResult)result {
//  result(@(_textureId));
//}
//
//@end
