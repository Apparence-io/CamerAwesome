//
//  AspectRatioUtils.h
//  camerawesome
//
//  Created by Dimitri Dessus on 29/03/2023.
//

#import <Foundation/Foundation.h>
#import "AspectRatio.h"

NS_ASSUME_NONNULL_BEGIN

@interface AspectRatioUtils : NSObject

+ (AspectRatio)convertAspectRatio:(NSString *)aspectRatioStr;

@end

NS_ASSUME_NONNULL_END
