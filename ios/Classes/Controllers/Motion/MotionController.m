//
//  MotionController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import "MotionController.h"

@implementation MotionController

- (instancetype)init {
  self = [super init];
  _motionManager = [[CMMotionManager alloc] init];
  _motionManager.deviceMotionUpdateInterval = 0.2f;
  return self;
}

- (void)setOrientationEventSink:(FlutterEventSink)orientationEventSink {
  _orientationEventSink = orientationEventSink;
}

/// Start live motion detection
- (void)startMotionDetection {
  [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                      withHandler:^(CMDeviceMotion *data, NSError *error) {
    UIDeviceOrientation newOrientation;
    if(fabs(data.gravity.x) > fabs(data.gravity.y)) {
      // Landscape
      newOrientation = (data.gravity.x >= 0) ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationLandscapeRight;
    } else {
      // Portrait
      newOrientation = (data.gravity.y >= 0) ? UIDeviceOrientationPortraitUpsideDown : UIDeviceOrientationPortrait;
    }
    if (self->_deviceOrientation != newOrientation) {
      self->_deviceOrientation = newOrientation;
      
      NSString *orientationString;
      switch (newOrientation) {
        case UIDeviceOrientationLandscapeLeft:
          orientationString = @"LANDSCAPE_LEFT";
          break;
        case UIDeviceOrientationLandscapeRight:
          orientationString = @"LANDSCAPE_RIGHT";
          break;
        case UIDeviceOrientationPortrait:
          orientationString = @"PORTRAIT_UP";
          break;
        case UIDeviceOrientationPortraitUpsideDown:
          orientationString = @"PORTRAIT_DOWN";
          break;
        default:
          break;
      }
      if (self->_orientationEventSink != nil) {
        self->_orientationEventSink(orientationString);
      }
    }
  }];
}

/// Stop motion update
- (void)stopMotionDetection {
  [_motionManager stopDeviceMotionUpdates];
}

@end
