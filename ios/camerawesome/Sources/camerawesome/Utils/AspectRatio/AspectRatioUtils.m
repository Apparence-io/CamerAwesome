//
//  AspectRatioUtils.m
//  camerawesome
//
//  Created by Dimitri Dessus on 29/03/2023.
//

#import "AspectRatioUtils.h"

@implementation AspectRatioUtils

+ (AspectRatio)convertAspectRatio:(NSString *)aspectRatioStr {
  AspectRatio aspectRatioMode;
  if ([aspectRatioStr isEqualToString:@"RATIO_4_3"]) {
    aspectRatioMode = Ratio4_3;
  } else if ([aspectRatioStr isEqualToString:@"RATIO_16_9"]) {
    aspectRatioMode = Ratio16_9;
  } else {
    aspectRatioMode = Ratio1_1;
  }
  return aspectRatioMode;
}

@end
