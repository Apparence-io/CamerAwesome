//
//  FlashModeUtils.m
//  camerawesome
//
//  Created by Dimitri Dessus on 29/03/2023.
//

#import "FlashModeUtils.h"

@implementation FlashModeUtils

+ (CameraFlashMode)flashFromString:(NSString *)mode {
  CameraFlashMode flash;
  
  if ([mode isEqualToString:@"NONE"]) {
    flash = None;
  } else if ([mode isEqualToString:@"ON"]) {
    flash = On;
  } else if ([mode isEqualToString:@"AUTO"]) {
    flash = Auto;
  } else if ([mode isEqualToString:@"ALWAYS"]) {
    flash = Always;
  } else {
    flash = None;
  }
  
  return flash;
}

@end
