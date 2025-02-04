//
//  PermissionsController.h
//  _NIODataStructures
//
//  Created by Dimitri Dessus on 27/12/2022.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraPermissionsController : NSObject

+ (BOOL)checkPermission;
+ (BOOL)checkAndRequestPermission;

@end

@interface MicrophonePermissionsController : NSObject

+ (BOOL)checkPermission;
+ (BOOL)checkAndRequestPermission;

@end

NS_ASSUME_NONNULL_END
