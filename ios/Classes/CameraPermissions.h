//
//  CameraPermissions.h
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraPermissions : NSObject

+ (BOOL)checkPermissions;

@end

NS_ASSUME_NONNULL_END
