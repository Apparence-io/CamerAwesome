//
//  CameraPicture.h
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraPicture : NSObject <AVCapturePhotoCaptureDelegate>
@property(readonly, nonatomic) NSString *path;
@property(readonly, nonatomic) FlutterResult result;
@property NSInteger orientation;
@property CGSize pictureSize;
@property(readonly, nonatomic) CMMotionManager *motionManager;
@property(readonly, nonatomic) AVCaptureDevicePosition cameraPosition;
- (instancetype)initWithPath:(NSString *)path
                 orientation:(NSInteger)orientation
                 captureSize:(CGSize)pictureSize
                      result:(FlutterResult)result;
@end

NS_ASSUME_NONNULL_END

