//
//  ImageStreamController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import "ImageStreamController.h"

@implementation ImageStreamController

NSInteger const MaxPendingProcessedImage = 4;

- (instancetype)initWithStreamImages:(bool)streamImages {
  self = [super init];
  _streamImages = streamImages;
  _processingImage = 0;
  return self;
}

# pragma mark - Camera Delegates
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection orientation:(UIDeviceOrientation)orientation {
  if (_imageStreamEventSink == nil) {
    return;
  }
  
  bool shouldFPSGuard = [self fpsGuard];
  bool shouldOverflowCrashingGuard = [self overflowCrashingGuard];
  
  if (shouldFPSGuard || shouldOverflowCrashingGuard) {
    return;
  }
  
  _processingImage++;
  
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  
  size_t imageWidth = CVPixelBufferGetWidth(pixelBuffer);
  size_t imageHeight = CVPixelBufferGetHeight(pixelBuffer);
  
  NSMutableArray *planes = [NSMutableArray array];
  
  const Boolean isPlanar = CVPixelBufferIsPlanar(pixelBuffer);
  size_t planeCount;
  if (isPlanar) {
    planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
  } else {
    planeCount = 1;
  }
  
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
    
    [planes addObject:@{
      @"bytesPerRow": @(bytesPerRow),
      @"width": @(width),
      @"height": @(height),
      @"bytes": [FlutterStandardTypedData typedDataWithBytes:bytes],
    }];
  }
  
  CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  
  NSDictionary *imageBuffer = @{
    @"width": [NSNumber numberWithUnsignedLong:imageWidth],
    @"height": [NSNumber numberWithUnsignedLong:imageHeight],
    @"format": @"bgra8888", // TODO: change this dynamically
    @"planes": planes,
    @"rotation": [self getInputImageOrientation:orientation]
  };
  
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_imageStreamEventSink(imageBuffer);
  });
  
}

- (NSString *)getInputImageOrientation:(UIDeviceOrientation)orientation {
  switch (orientation) {
    case UIDeviceOrientationLandscapeLeft:
      return @"rotation90deg";
    case UIDeviceOrientationLandscapeRight:
      return @"rotation270deg";
    case UIDeviceOrientationPortrait:
      return @"rotation0deg";
    case UIDeviceOrientationPortraitUpsideDown:
      return @"rotation180deg";
    default:
      return @"rotation0deg";
  }
}

#pragma mark - Guards

- (bool)fpsGuard {
  // calculate time interval between latest emitted frame
  NSDate *nowDate = [NSDate date];
  NSTimeInterval secondsBetween = [nowDate timeIntervalSinceDate:_latestEmittedFrame];
  
  // fps limit check, ignored if nil or == 0
  if (_maxFramesPerSecond && _maxFramesPerSecond > 0) {
    if (secondsBetween <= (1 / _maxFramesPerSecond)) {
      // skip image because out of time
      return YES;
    }
  }
  
  return NO;
}

- (bool)overflowCrashingGuard {
  // overflow crash prevent condition
  if (_processingImage > MaxPendingProcessedImage) {
    // too many frame are pending processing, skipping...
    // this prevent crashing on older phones like iPhone 6, 7...
    return YES;
  }
  
  return NO;
}

// This is used to know the exact time when the image was received on the Flutter part
- (void)receivedImageFromStream {
  // used for the fps limit condition
  _latestEmittedFrame = [NSDate date];
  
  // used for the overflow prevent crashing condition
  if (_processingImage >= 0) {
    _processingImage--;
  }
}

#pragma mark - Setters

- (void)setImageStreamEventSink:(FlutterEventSink)imageStreamEventSink {
  _imageStreamEventSink = imageStreamEventSink;
}

- (void)setMaxFramesPerSecond:(float)maxFramesPerSecond {
  _maxFramesPerSecond = maxFramesPerSecond;
}

- (void)setStreamImages:(bool)streamImages {
  _streamImages = streamImages;
}

@end
