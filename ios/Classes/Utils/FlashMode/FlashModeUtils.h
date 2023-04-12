//
//  FlashModeUtils.h
//  camerawesome
//
//  Created by Dimitri Dessus on 29/03/2023.
//

#import <Foundation/Foundation.h>
#import "CameraFlash.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlashModeUtils : NSObject

+ (CameraFlashMode)flashFromString:(NSString *)mode;

@end

NS_ASSUME_NONNULL_END
