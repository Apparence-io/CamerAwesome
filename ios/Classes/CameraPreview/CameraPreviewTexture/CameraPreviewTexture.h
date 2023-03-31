//
//  CameraPreviewTexture.h
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#include <stdatomic.h>
#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraPreviewTexture : NSObject<FlutterTexture>

- (instancetype)init;
- (void)updateBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)dealloc;

@property(readonly) _Atomic(CVPixelBufferRef) latestPixelBuffer;

@end

NS_ASSUME_NONNULL_END
