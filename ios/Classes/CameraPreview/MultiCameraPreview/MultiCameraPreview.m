//
//  MultiCameraPreview.m
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import "MultiCameraPreview.h"

@implementation MultiCameraPreview

- (instancetype)init {
  if (self = [super init]) {
    _dataOutputQueue = dispatch_queue_create("data.output.queue", NULL);
    
    [self configSession];
  }
  
  return self;
}

- (void)configSession {
  if (AVCaptureMultiCamSession.isMultiCamSupported == NO) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return;
  }
  
  self.backPreviewTexture = [[CameraPreviewTexture alloc] init];
  self.frontPreviewTexture = [[CameraPreviewTexture alloc] init];
  
  self.cameraSession = [[AVCaptureMultiCamSession alloc] init];
  [self.cameraSession beginConfiguration];
  
  if ([self configBackCamera] == NO) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    [self.cameraSession commitConfiguration];
    return;
  }
  
  if ([self configFrontCamera] == NO) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    [self.cameraSession commitConfiguration];
    return;
  }
  
  [self.cameraSession commitConfiguration];
}

- (void)start {
  [_cameraSession startRunning];
}

- (CGSize)getEffectivPreviewSize {
  // TODO
  return CGSizeMake(1920, 1080);
}

- (BOOL)configFrontCamera {
  AVCaptureDevice *frontCamera = [self.class getCaptureDeviceWithPosition:AVCaptureDevicePositionFront];
  if (frontCamera == nil) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  
  NSError *error = nil;
  self.frontDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontCamera error:&error];
  if (![self.cameraSession canAddInput:self.frontDeviceInput]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  [self.cameraSession addInputWithNoConnections:self.frontDeviceInput];
  
  self.frontVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
  self.frontVideoDataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
  [self.frontVideoDataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
  
  if (![self.cameraSession canAddOutput:self.frontVideoDataOutput]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  [self.cameraSession addOutputWithNoConnections:self.frontVideoDataOutput];
  
  AVCaptureInputPort *port = [[self.frontDeviceInput portsWithMediaType:AVMediaTypeVideo
                                                       sourceDeviceType:frontCamera.deviceType
                                                   sourceDevicePosition:frontCamera.position] firstObject];
  AVCaptureConnection *frontConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[port] output:self.frontVideoDataOutput];
  
  if (![self.cameraSession canAddConnection:frontConnection]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  [self.cameraSession addConnection:frontConnection];
  [frontConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
  [frontConnection setAutomaticallyAdjustsVideoMirroring:NO];
  [frontConnection setVideoMirrored:YES];
  
  self.frontPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.cameraSession];
  AVCaptureConnection *frontPreviewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:port videoPreviewLayer:self.frontPreviewLayer];
  [frontPreviewLayerConnection setAutomaticallyAdjustsVideoMirroring:NO];
  [frontPreviewLayerConnection setVideoMirrored:YES];
  self.frontPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  if (![self.cameraSession canAddConnection:frontPreviewLayerConnection]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  
  return YES;
}

- (BOOL)configBackCamera {
  AVCaptureDevice *backCamera = [self.class getCaptureDeviceWithPosition:AVCaptureDevicePositionBack];
  if (backCamera == nil) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  
  NSError *error = nil;
  self.backDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:backCamera error:&error];
  if (![self.cameraSession canAddInput:self.backDeviceInput]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  [self.cameraSession addInputWithNoConnections:self.backDeviceInput];
  
  self.backVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
  self.backVideoDataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
  [self.backVideoDataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
  
  if (![self.cameraSession canAddOutput:self.backVideoDataOutput]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  [self.cameraSession addOutputWithNoConnections:self.backVideoDataOutput];
  
  AVCaptureInputPort *port = [[self.backDeviceInput portsWithMediaType:AVMediaTypeVideo
                                                      sourceDeviceType:backCamera.deviceType
                                                  sourceDevicePosition:backCamera.position] firstObject];
  AVCaptureConnection *backConnection = [[AVCaptureConnection alloc] initWithInputPorts:@[port] output:self.backVideoDataOutput];
  
  if (![self.cameraSession canAddConnection:backConnection]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  [self.cameraSession addConnection:backConnection];
  [backConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
  [backConnection setAutomaticallyAdjustsVideoMirroring:NO];
  [backConnection setVideoMirrored:NO];
  
  self.backPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSessionWithNoConnection:self.cameraSession];
  AVCaptureConnection *backPreviewLayerConnection = [[AVCaptureConnection alloc] initWithInputPort:port videoPreviewLayer:self.backPreviewLayer];
  //    [backPreviewLayerConnection setAutomaticallyAdjustsVideoMirroring:YES];
  //    [backPreviewLayerConnection setVideoMirrored:NO];
  self.backPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  self.backPreviewLayer.frame = [[UIScreen mainScreen] bounds];
  if (![self.cameraSession canAddConnection:backPreviewLayerConnection]) {
    NSLog(@"%s, %d", __PRETTY_FUNCTION__, __LINE__);
    return NO;
  }
  
  [self.cameraSession addConnection:backPreviewLayerConnection];
  
  return YES;
}

// TODO: move this to SensorsController
+ (AVCaptureDevice *)getCaptureDeviceWithPosition:(AVCaptureDevicePosition)position {
  return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
}

- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error {
  // TODO:
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  if (output == self.frontVideoDataOutput) {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [_frontPreviewTexture updateBuffer:sampleBuffer];
    if (_onPreviewFrontFrameAvailable) {
      _onPreviewFrontFrameAvailable();
    }
  } else if (output == self.backVideoDataOutput) {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);    
    [_backPreviewTexture updateBuffer:sampleBuffer];
    if (_onPreviewBackFrameAvailable) {
      _onPreviewBackFrameAvailable();
    }
  }
}

@end
