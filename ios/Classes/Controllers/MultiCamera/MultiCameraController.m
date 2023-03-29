//
//  MultiCameraController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 29/03/2023.
//

#import "MultiCameraController.h"

@implementation MultiCameraController

+ (BOOL)isMultiCamSupported {
  return AVCaptureMultiCamSession.isMultiCamSupported;
}

@end
