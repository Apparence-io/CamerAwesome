//
//  MultiCameraPreview.m
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import "MultiCameraPreview.h"

@implementation MultiCameraPreview

- (instancetype)initWithSensors:(NSArray<Sensor *> *)sensors mirrorFrontCamera:(BOOL)mirrorFrontCamera
           enablePhysicalButton:(BOOL)enablePhysicalButton
                aspectRatioMode:(AspectRatio)aspectRatioMode
                    captureMode:(CaptureModes)captureMode {
  if (self = [super init]) {
    _dataOutputQueue = dispatch_queue_create("data.output.queue", NULL);
    
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
}

- (void)stop {
  [_cameraSession stopRunning];
}

- (void)configSession:(NSArray<Sensor *> *)sensors {
  [_textures removeAllObjects];
  [_devices removeAllObjects];
  
  _sensors = sensors;
  
  for (int i = 0; i < [sensors count]; i++) {
    CameraPreviewTexture *previewTexture = [[CameraPreviewTexture alloc] init];
    [_textures addObject:previewTexture];
  }
  
  self.cameraSession = [[AVCaptureMultiCamSession alloc] init];
  [self.cameraSession beginConfiguration];
  
  // Creating photo output
  _capturePhotoOutput = [AVCapturePhotoOutput new];
  [_capturePhotoOutput setHighResolutionCaptureEnabled:YES];
  [_cameraSession addOutput:_capturePhotoOutput];
  
  int index = 0;
  for (Sensor *sensor in sensors) {
    [self addSensor:sensor withIndex:index];
    [self.cameraSession commitConfiguration];
    index++;
  }
  
  // TODO:
  
  //  if ([self configBackCamera] == NO) {
  //    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
  //    [self.cameraSession commitConfiguration];
  //    return;
  //  }
  //
  //  if ([self configFrontCamera] == NO) {
  //    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
  //    [self.cameraSession commitConfiguration];
  //    return;
  //  }
  //
  //  [self.cameraSession commitConfiguration];
}

- (void)start {
  [_cameraSession startRunning];
}

- (CGSize)getEffectivPreviewSize {
  // TODO
  return CGSizeMake(1920, 1080);
}

- (BOOL)addSensor:(Sensor *)sensor withIndex:(int)index {
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
  [cameraDevice.videoDataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
  
  if (![self.cameraSession canAddOutput:cameraDevice.videoDataOutput]) {
    return NO;
  }
  [self.cameraSession addOutputWithNoConnections:cameraDevice.videoDataOutput];
  
  AVCaptureInputPort *port = [[cameraDevice.deviceInput portsWithMediaType:AVMediaTypeVideo
                                                          sourceDeviceType:device.deviceType
                                                      sourceDevicePosition:device.position] firstObject];
  AVCaptureConnection *connection = [[AVCaptureConnection alloc] initWithInputPorts:@[port] output:cameraDevice.videoDataOutput];
  
  if (![self.cameraSession canAddConnection:connection]) {
    return NO;
  }
  [self.cameraSession addConnection:connection];
  
  [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
  [connection setAutomaticallyAdjustsVideoMirroring:NO];
  [connection setVideoMirrored:sensor.position == SensorPositionFront];
  
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
- (AVCaptureDevice *)selectAvailableCamera:(Sensor *)sensor {
  // TODO: add dual & triple camera
  NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
  AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                       discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera, ]
                                                       mediaType:AVMediaTypeVideo
                                                       position:AVCaptureDevicePositionUnspecified];
  devices = discoverySession.devices;
  
  NSInteger cameraType = (sensor.position == SensorPositionFront) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
  for (AVCaptureDevice *device in devices) {
    if ([device position] == cameraType) {
      return [AVCaptureDevice deviceWithUniqueID:[device uniqueID]];
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
  // Instanciate camera picture obj
  CameraPictureController *cameraPicture = [[CameraPictureController alloc] initWithPath:path
                                                                             orientation:_motionController.deviceOrientation
                                                                                  sensor:_sensors.firstObject.position
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
  
  [_capturePhotoOutput capturePhotoWithSettings:settings
                                       delegate:cameraPicture];
}

// TODO: move this to SensorsController
+ (AVCaptureDevice *)getCaptureDeviceWithPosition:(AVCaptureDevicePosition)position {
  return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
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
