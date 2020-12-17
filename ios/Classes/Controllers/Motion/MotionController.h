//
//  MotionController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface MotionController : NSObject

@property(nonatomic) FlutterEventSink orientationEventSink;
@property(readonly, nonatomic) UIDeviceOrientation deviceOrientation;
@property(readonly, nonatomic) CMMotionManager *motionManager;

- (instancetype)initWithEventSink:(FlutterEventSink)orientationEventSink;
- (void)startMotionDetection;
- (void)stopMotionDetection;

@end

NS_ASSUME_NONNULL_END
