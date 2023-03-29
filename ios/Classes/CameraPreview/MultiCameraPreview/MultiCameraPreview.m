//
//  MultiCameraPreview.m
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import "MultiCameraPreview.h"

@implementation MultiCameraPreview

//- (instancetype)init {
//  if (self = [super init]) {
//    _dataOutputQueue = dispatch_queue_create("data.output.queue", NULL);
//
//    [self configSession];
//  }
//
//  return self;
//}

- (instancetype)initWithSensors:(NSArray<Sensor *> *)sensors {
  if (self = [super init]) {
    _dataOutputQueue = dispatch_queue_create("data.output.queue", NULL);
    
    _textures = [NSMutableArray new];
    _devices = [NSMutableArray new];
    
    [self configSession:sensors];
  }
  
  return self;
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
  
  for (int i = 0; i < [sensors count]; i++) {
    CameraPreviewTexture *previewTexture = [[CameraPreviewTexture alloc] init];
    [_textures addObject:previewTexture];
  }
  
  self.cameraSession = [[AVCaptureMultiCamSession alloc] init];
  [self.cameraSession beginConfiguration];
  
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

//
//- (BOOL)configFrontCamera {
//  AVCaptureDevice *frontCamera = [self.class getCaptureDeviceWithPosition:AVCaptureDevicePositionFront];
//  if (frontCamera == nil) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//
//  NSError *error = nil;
//  self.frontDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontCamera error:&error];
//  if (![self.cameraSession canAddInput:self.frontDeviceInput]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//  [self.cameraSession addInputWithNoConnections:self.frontDeviceInput];
//
//  self.frontVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
//  self.frontVideoDataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
//  [self.frontVideoDataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
//
//  if (![self.cameraSession canAddOutput:self.frontVideoDataOutput]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//  [self.cameraSession addOutputWithNoConnections:self.frontVideoDataOutput];
//
//  AVCaptureInputPort *port = [[self.frontDeviceInput portsWithMediaType:AVMediaTypeVideo
//                                                       sourceDeviceType:frontCamera.deviceType
//                                                   sourceDevicePosition:frontCamera.position] firstObject];
//  AVCaptureConnection *frontConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[port] output:self.frontVideoDataOutput];
//
//  if (![self.cameraSession canAddConnection:frontConnection]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//  [self.cameraSession addConnection:frontConnection];
//  [frontConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
//  [frontConnection setAutomaticallyAdjustsVideoMirroring:NO];
//  [frontConnection setVideoMirrored:YES];
//
//  self.frontPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.cameraSession];
//  AVCaptureConnection *frontPreviewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:port videoPreviewLayer:self.frontPreviewLayer];
//  [frontPreviewLayerConnection setAutomaticallyAdjustsVideoMirroring:NO];
//  [frontPreviewLayerConnection setVideoMirrored:YES];
//  self.frontPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//  if (![self.cameraSession canAddConnection:frontPreviewLayerConnection]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//
//  return YES;
//}
//
//- (BOOL)configBackCamera {
//  AVCaptureDevice *backCamera = [self.class getCaptureDeviceWithPosition:AVCaptureDevicePositionBack];
//  if (backCamera == nil) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//
//  NSError *error = nil;
//  self.backDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:backCamera error:&error];
//  if (![self.cameraSession canAddInput:self.backDeviceInput]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//  [self.cameraSession addInputWithNoConnections:self.backDeviceInput];
//
//  self.backVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
//  self.backVideoDataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
//  [self.backVideoDataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
//
//  if (![self.cameraSession canAddOutput:self.backVideoDataOutput]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//  [self.cameraSession addOutputWithNoConnections:self.backVideoDataOutput];
//
//  AVCaptureInputPort *port = [[self.backDeviceInput portsWithMediaType:AVMediaTypeVideo
//                                                      sourceDeviceType:backCamera.deviceType
//                                                  sourceDevicePosition:backCamera.position] firstObject];
//  AVCaptureConnection *backConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[port] output:self.backVideoDataOutput];
//
//  if (![self.cameraSession canAddConnection:backConnection]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//  [self.cameraSession addConnection:backConnection];
//  [backConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
//  [backConnection setAutomaticallyAdjustsVideoMirroring:NO];
//  [backConnection setVideoMirrored:NO];
//
//  self.backPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.cameraSession];
//  AVCaptureConnection *backPreviewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:port videoPreviewLayer:self.backPreviewLayer];
//  //    [backPreviewLayerConnection setAutomaticallyAdjustsVideoMirroring:YES];
//  //    [backPreviewLayerConnection setVideoMirrored:NO];
//  self.backPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//  self.backPreviewLayer.frame = [[UIScreen mainScreen] bounds];
//  if (![self.cameraSession canAddConnection:backPreviewLayerConnection]) {
//    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
//    return NO;
//  }
//
//  [self.cameraSession addConnection:backPreviewLayerConnection];
//
//  return YES;
//}

// TODO: move this to SensorsController
+ (AVCaptureDevice *)getCaptureDeviceWithPosition:(AVCaptureDevicePosition)position {
  return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
}

- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  // TODO:
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  // TODO:
  int index = 0;
  for (CameraDeviceInfo *device in _devices) {
    if (device.videoDataOutput == output) {
      //CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
      [_textures[index] updateBuffer:sampleBuffer];
      if (_onPreviewFrameAvailable) {
        _onPreviewFrameAvailable(@(index));
      }
    }
    
    index++;
  }
  
  //  if (output == self.frontVideoDataOutput) {
  //    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  //    [_textures[0] updateBuffer:sampleBuffer];
  //    if (_onPreviewFrameAvailable) {
  //      _onPreviewFrameAvailable(@(0));
  //    }
  //  } else if (output == self.backVideoDataOutput) {
  //    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  //    [_textures[1] updateBuffer:sampleBuffer];
  //    if (_onPreviewFrameAvailable) {
  //      _onPreviewFrameAvailable(@(1));
  //    }
  //  }
}

@end
