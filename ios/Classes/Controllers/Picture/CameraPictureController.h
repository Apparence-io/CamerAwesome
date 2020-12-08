//
//  CameraPictureController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 08/12/2020.
//

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

#import "CameraSensor.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnPictureTaken)(void);

@interface CameraPictureController : NSObject <AVCapturePhotoCaptureDelegate>
@property(readonly, nonatomic) NSString *path;
@property(readonly, nonatomic) FlutterResult result;
@property(readonly, nonatomic) CameraSensor sensor;
@property NSInteger orientation;
@property (nonatomic, copy) OnPictureTaken completionBlock;
@property(readonly, nonatomic) CMMotionManager *motionManager;
@property(readonly, nonatomic) AVCaptureDevicePosition cameraPosition;

- (instancetype)initWithPath:(NSString *)path
                 orientation:(NSInteger)orientation
                      sensor:(CameraSensor)sensor
                      result:(FlutterResult)result
                    callback:(OnPictureTaken)callback;
@end

NS_ASSUME_NONNULL_END

