//
//  CaptureModeUtils.h
//  camerawesome
//
//  Created by Dimitri Dessus on 10/05/2023.
//

#import <Foundation/Foundation.h>
#import "CaptureModes.h"

NS_ASSUME_NONNULL_BEGIN

@interface CaptureModeUtils : NSObject

+ (CaptureModes)captureModeFromCaptureModeType:(NSString *)captureModeType;

@end

NS_ASSUME_NONNULL_END
