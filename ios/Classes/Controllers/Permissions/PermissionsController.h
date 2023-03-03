//
//  PermissionsController.h
//  _NIODataStructures
//
//  Created by Dimitri Dessus on 27/12/2022.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PermissionsController : NSObject

+ (BOOL)checkCameraPermission;
+ (BOOL)checkAndRequestCameraPermission;
+ (BOOL)checkMicrophonePermission;
+ (BOOL)checkAndRequestMicrophonePermission;

@end

NS_ASSUME_NONNULL_END
