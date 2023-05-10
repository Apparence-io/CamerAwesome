//
//  CaptureModeUtils.m
//  camerawesome
//
//  Created by Dimitri Dessus on 10/05/2023.
//

#import "CaptureModeUtils.h"

@implementation CaptureModeUtils

+ (CaptureModes)captureModeFromCaptureModeType:(NSString *)captureModeType {
  if ([captureModeType isEqualToString:@"PHOTO"]) {
    return Photo;
  } else if ([captureModeType isEqualToString:@"VIDEO"]) {
    return Video;
  } else {
    return Preview;
  }
}

@end
