//
//  ImageStreamController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "InputImageRotation.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageStreamController : NSObject

@property(readonly, nonatomic) bool streamImages;
@property(readonly, nonatomic) float maxFramesPerSecond;
@property(readonly, nonatomic) NSDate *latestEmittedFrame;
@property(nonatomic) FlutterEventSink imageStreamEventSink;

@property(readonly, nonatomic) NSInteger processingImage;

- (instancetype)initWithStreamImages:(bool)streamImages;
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection orientation:(UIDeviceOrientation)orientation;
- (void)setImageStreamEventSink:(FlutterEventSink)imageStreamEventSink;
- (void)setStreamImages:(bool)streamImages;
- (void)receivedImageFromStream;
- (void)setMaxFramesPerSecond:(float)maxFramesPerSecond;

@end

NS_ASSUME_NONNULL_END
