//
//  MultiCameraPreview.m
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import "MultiCameraPreview.h"

@implementation MultiCameraPreview

- (instancetype)initWithSensors:(NSArray<PigeonSensor *> *)sensors mirrorFrontCamera:(BOOL)mirrorFrontCamera
           enablePhysicalButton:(BOOL)enablePhysicalButton
                aspectRatioMode:(AspectRatio)aspectRatioMode
                    captureMode:(CaptureModes)captureMode
                  dispatchQueue:(dispatch_queue_t)dispatchQueue {
  if (self = [super init]) {
    _dispatchQueue = dispatchQueue;
    
    _textures = [NSMutableArray new];
    _devices = [NSMutableArray new];
    
    _motionController = [[MotionController alloc] init];
    _physicalButtonController = [[PhysicalButtonController alloc] init];
    
    if (enablePhysicalButton) {
      [_physicalButtonController startListening];
    }
    
    [_motionController startMotionDetection];
    
    [self configSession:sensors];
  }
  
  return self;
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

- (void)dispose {
  [self stop];
  [self cleanSession];
}

- (void)stop {
  [self.cameraSession stopRunning];
}

- (void)cleanSession {
  for (AVCaptureInput *input in [_cameraSession inputs]) {
    [self.cameraSession removeInput:input];
  }
  
  for (AVCaptureOutput *output in [_cameraSession outputs]) {
    [self.cameraSession removeOutput:output];
  }
  
  for (AVCaptureConnection *connection in [_cameraSession connections]) {
    [self.cameraSession removeConnection:connection];
  }
  
  [self.textures removeAllObjects];
  [self.devices removeAllObjects];
  
  _cameraSession = nil;
}

- (void)configSession:(NSArray<PigeonSensor *> *)sensors {
  [self cleanSession];
  
  _sensors = sensors;
  
  self.cameraSession = [[AVCaptureMultiCamSession alloc] init];
  [self.cameraSession beginConfiguration];
  
  for (int i = 0; i < [sensors count]; i++) {
    PigeonSensor *sensor = sensors[i];
    
    CameraPreviewTexture *previewTexture = [[CameraPreviewTexture alloc] init];
    [_textures addObject:previewTexture];
    
    [self addSensor:sensor withIndex:i];
    [self.cameraSession commitConfiguration];
  }
  
  // Creating photo output
  self.capturePhotoOutput = [AVCapturePhotoOutput new];
  [self.capturePhotoOutput setHighResolutionCaptureEnabled:YES];
  [self.cameraSession addOutput:self.capturePhotoOutput];
  
  [self.cameraSession commitConfiguration];
}

- (void)start {
  [_cameraSession startRunning];
}

- (CGSize)getEffectivPreviewSize {
  // TODO
  return CGSizeMake(1920, 1080);
}

- (BOOL)addSensor:(PigeonSensor *)sensor withIndex:(int)index {
  AVCaptureDevice *device = [self selectAvailableCamera:sensor];;
  
  if (device == nil) {
    return NO;
  }
  
  // move this all this in the cameradevice object
  CameraDeviceInfo *cameraDevice = [[CameraDeviceInfo alloc] init];
  
  NSError *error = nil;
  cameraDevice.deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
  if (![self.cameraSession canAddInput:cameraDevice.deviceInput]) {
    return NO;
  }
  [self.cameraSession addInputWithNoConnections:cameraDevice.deviceInput];
  
  cameraDevice.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
  cameraDevice.videoDataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
  [cameraDevice.videoDataOutput setSampleBufferDelegate:self queue:self.dispatchQueue];
  
  if (![self.cameraSession canAddOutput:cameraDevice.videoDataOutput]) {
    return NO;
  }
  [self.cameraSession addOutputWithNoConnections:cameraDevice.videoDataOutput];
  
  AVCaptureInputPort *port = [[cameraDevice.deviceInput portsWithMediaType:AVMediaTypeVideo
                                                          sourceDeviceType:device.deviceType
                                                      sourceDevicePosition:device.position] firstObject];
  cameraDevice.captureConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[port] output:cameraDevice.videoDataOutput];
  
  if (![self.cameraSession canAddConnection:cameraDevice.captureConnection]) {
    return NO;
  }
  [self.cameraSession addConnection:cameraDevice.captureConnection];
  
  [cameraDevice.captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
  [cameraDevice.captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
  [cameraDevice.captureConnection setVideoMirrored:sensor.position == PigeonSensorPositionFront];
  
  cameraDevice.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.cameraSession];
  AVCaptureConnection *frontPreviewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:port videoPreviewLayer:cameraDevice.previewLayer];
  [frontPreviewLayerConnection setAutomaticallyAdjustsVideoMirroring:NO];
  [frontPreviewLayerConnection setVideoMirrored:YES];
  cameraDevice.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  if (![self.cameraSession canAddConnection:frontPreviewLayerConnection]) {
    return NO;
  }
  
  [_devices addObject:cameraDevice];
  
  return YES;
}

/// Get the first available camera on device (front or rear)
- (AVCaptureDevice *)selectAvailableCamera:(PigeonSensor *)sensor {
  if (sensor.deviceId != nil) {
    return [AVCaptureDevice deviceWithUniqueID:sensor.deviceId];
  }
  
  // TODO: add dual & triple camera
  NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
  AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                       discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, AVCaptureDeviceTypeBuiltInUltraWideCamera, ]
                                                       mediaType:AVMediaTypeVideo
                                                       position:AVCaptureDevicePositionUnspecified];
  devices = discoverySession.devices;
  
  for (AVCaptureDevice *device in devices) {
    if (sensor.type != PigeonSensorTypeUnknown) {
      AVCaptureDeviceType deviceType = [SensorUtils deviceTypeFromSensorType:sensor.type];
      if ([device deviceType] == deviceType) {
        return [AVCaptureDevice deviceWithUniqueID:[device uniqueID]];
      }
    } else if (sensor.position != PigeonSensorPositionUnknown) {
      NSInteger cameraType = (sensor.position == PigeonSensorPositionFront) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
      if ([device position] == cameraType) {
        return [AVCaptureDevice deviceWithUniqueID:[device uniqueID]];
      }
    }
  }
  return nil;
}

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

- (void)setAspectRatio:(AspectRatio)ratio {
  _aspectRatio = ratio;
}

- (void)takePictureAtPath:(NSString *)path completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion {
  CameraPictureController *cameraPicture = [[CameraPictureController alloc] initWithPath:path
                                                                             orientation:_motionController.deviceOrientation
                                                                          sensorPosition:_sensors[1].position
                                                                         saveGPSLocation:_saveGPSLocation
                                                                       mirrorFrontCamera:_mirrorFrontCamera
                                                                             aspectRatio:_aspectRatio
                                                                              completion:completion
                                                                                callback:^{
    completion(@(YES), nil);
  }];
  
  // Create settings instance
  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
  [settings setHighResolutionPhotoEnabled:YES];
  [self.capturePhotoOutput setPhotoSettingsForSceneMonitoring:settings];
  
  [_capturePhotoOutput capturePhotoWithSettings:settings
                                       delegate:cameraPicture];
}

- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  // TODO:
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  int index = 0;
  for (CameraDeviceInfo *device in _devices) {
    if (device.videoDataOutput == output) {
      [_textures[index] updateBuffer:sampleBuffer];
      if (_onPreviewFrameAvailable) {
        _onPreviewFrameAvailable(@(index));
      }
    }
    
    index++;
  }
}

@end
