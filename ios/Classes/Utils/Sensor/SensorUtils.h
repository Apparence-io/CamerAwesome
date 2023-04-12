//
//  SensorUtils.h
//  camerawesome
//
//  Created by Dimitri Dessus on 30/03/2023.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Pigeon.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorUtils : NSObject

+ (PigeonSensorType)sensorTypeFromDeviceType:(AVCaptureDeviceType)type;
+ (AVCaptureDeviceType)deviceTypeFromSensorType:(PigeonSensorType)sensorType;

@end

NS_ASSUME_NONNULL_END
