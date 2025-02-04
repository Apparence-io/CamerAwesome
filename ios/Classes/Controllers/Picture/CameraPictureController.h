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
#import <CoreLocation/CoreLocation.h>

#import "CameraSensor.h"
#import "AspectRatio.h"
#import "Pigeon.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnPictureTaken)(void);

@interface CameraPictureController : NSObject <AVCapturePhotoCaptureDelegate>
@property(readonly, nonatomic) NSString *path;
@property(readonly, nonatomic) bool saveGPSLocation;
@property(readonly, nonatomic) bool mirrorFrontCamera;
@property(readonly, copy) void (^completion)(NSNumber * _Nullable, FlutterError * _Nullable);
@property(readonly, nonatomic) PigeonSensorPosition sensorPosition;
@property(readonly, nonatomic) float aspectRatio;
@property(readonly, nonatomic) AspectRatio aspectRatioType;
@property NSInteger orientation;
@property (nonatomic, copy) OnPictureTaken completionBlock;
@property(readonly, nonatomic) CMMotionManager *motionManager;
@property(readonly, nonatomic) AVCaptureDevicePosition cameraPosition;

- (instancetype)initWithPath:(NSString *)path
                orientation:(NSInteger)orientation
            sensorPosition:(PigeonSensorPosition)sensorPosition
            saveGPSLocation:(bool)saveGPSLocation
          mirrorFrontCamera:(bool)mirrorFrontCamera
                aspectRatio:(AspectRatio)aspectRatio
                completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion
                  callback:(OnPictureTaken)callback;
@end

NS_ASSUME_NONNULL_END

