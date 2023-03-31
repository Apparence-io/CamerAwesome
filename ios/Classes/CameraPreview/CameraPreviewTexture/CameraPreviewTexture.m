//
//  CameraPreviewTexture.m
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import "CameraPreviewTexture.h"

@implementation CameraPreviewTexture

- (instancetype)init {
  if (self = [super init]) {
    
  }
  
  return self;
}

- (void)updateBuffer:(CMSampleBufferRef)sampleBuffer {
  // TODO: add Atomic(...)
  CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CFRetain(newBuffer);
  CVPixelBufferRef old = atomic_load(&_latestPixelBuffer);
  while (!atomic_compare_exchange_strong(&_latestPixelBuffer, &old, newBuffer)) {
    old = atomic_load(&_latestPixelBuffer);
  }
  if (old != nil) {
    CFRelease(old);
  }
}

/// Used to copy pixels to in-memory buffer
- (CVPixelBufferRef _Nullable)copyPixelBuffer {
  CVPixelBufferRef pixelBuffer = atomic_load(&_latestPixelBuffer);
  while (!atomic_compare_exchange_strong(&_latestPixelBuffer, &pixelBuffer, nil)) {
    pixelBuffer = atomic_load(&_latestPixelBuffer);
  }
  
  return pixelBuffer;
}

- (void)dealloc {
  if (self.latestPixelBuffer) {
    CFRelease(self.latestPixelBuffer);
  }
}

@end
