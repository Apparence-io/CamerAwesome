//
//  ImageStreamController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageStreamController : NSObject

@property(readonly, nonatomic) bool streamImages;
@property(nonatomic) FlutterEventSink imageStreamEventSink;

- (instancetype)initWithEventSink:(FlutterEventSink)imageStreamEventSink;
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end

NS_ASSUME_NONNULL_END
