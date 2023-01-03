//
//  ImageStreamController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import "ImageStreamController.h"

@implementation ImageStreamController

- (instancetype)initWithStreamImages:(bool)streamImages {
  self = [super init];
  _streamImages = streamImages;
  return self;
}

# pragma mark - Camera Delegates
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection orientation:(UIDeviceOrientation)orientation {
  if (_imageStreamEventSink == nil) {
    return;
  }
  
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
      return @"rotation270deg";
    case UIDeviceOrientationLandscapeRight:
      return @"rotation270deg";
    case UIDeviceOrientationPortrait:
      return @"rotation270deg";
    case UIDeviceOrientationPortraitUpsideDown:
      return @"rotation270deg";
    default:
      return @"rotation270deg";
  }
}

- (void)setImageStreamEventSink:(FlutterEventSink)imageStreamEventSink {
  _imageStreamEventSink = imageStreamEventSink;
}

- (void)setStreamImages:(bool)streamImages {
  _streamImages = streamImages;
}

@end
