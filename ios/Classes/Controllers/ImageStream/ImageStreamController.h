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
@property(nonatomic) FlutterEventSink imageStreamEventSink;

- (instancetype)initWithStreamImages:(bool)streamImages;
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection orientation:(UIDeviceOrientation)orientation;
- (void)setImageStreamEventSink:(FlutterEventSink)imageStreamEventSink;
- (void)setStreamImages:(bool)streamImages;

@end

NS_ASSUME_NONNULL_END
