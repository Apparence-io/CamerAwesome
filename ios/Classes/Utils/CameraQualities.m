//
//  CameraQualities.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraQualities.h"

// TODO: rework how qualities are working to be more easy
@implementation CameraQualities

+ (AVCaptureSessionPreset)selectVideoCapturePresset:(CGSize)size session:(AVCaptureSession *)session device:(AVCaptureDevice *)device {
  if (!CGSizeEqualToSize(CGSizeZero, size)) {
    AVCaptureSessionPreset bestPresset = [CameraQualities selectPresetForSize:size session:session];
    if ([session canSetSessionPreset:bestPresset]) {
      return bestPresset;
    }
  }
  
  return [self computeBestPressetWithSession:session device:device];
}

+ (NSString *)selectVideoCapturePresset:(AVCaptureSession *)session device:(AVCaptureDevice *)device {
  return [self computeBestPressetWithSession:session device:device];
}

+ (CGSize)getSizeForPresset:(NSString *)presset {
  if (presset == AVCaptureSessionPreset3840x2160) {
    return CGSizeMake(3840, 2160);
  } else if (presset == AVCaptureSessionPreset1920x1080) {
    return CGSizeMake(1920, 1080);
  } else if (presset == AVCaptureSessionPreset1280x720) {
    return CGSizeMake(1280, 720);
  } else if (presset == AVCaptureSessionPreset640x480) {
    return CGSizeMake(640, 480);
  } else if (presset == AVCaptureSessionPreset352x288) {
    return CGSizeMake(352, 288);
  } else {
    // Default to HD
    return CGSizeMake(1280, 720);
  }
}

+ (AVCaptureSessionPreset)computeBestPressetWithSession:(AVCaptureSession *)session device:(AVCaptureDevice *)device {
  NSArray *qualities = [CameraQualities captureFormatsForDevice:device];
  
  for (NSDictionary *quality in qualities) {
    CGSize qualitySize = CGSizeMake([quality[@"width"] floatValue], [quality[@"height"] floatValue]);
    AVCaptureSessionPreset currentPresset = [CameraQualities selectPresetForSize:qualitySize session:session];
    
    if ([session canSetSessionPreset:currentPresset]) {
      return currentPresset;
    }
  }
  
  // Default to HD
  return AVCaptureSessionPreset1280x720;
}

+ (NSString *)selectPresetForSize:(CGSize)size session:(AVCaptureSession *)session {
  if (size.width >= 2160 || size.height >= 3840) {
    if (@available(iOS 9.0, *)) {
      // we don't know the exact size, so we check if it can apply
      // if not, apply basic 1920x1080
      if ([session canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
        return AVCaptureSessionPreset3840x2160;
      } else {
        return AVCaptureSessionPreset1920x1080;
      }
      return AVCaptureSessionPreset3840x2160;
    } else {
      return AVCaptureSessionPreset1920x1080;
    }
  } else if (size.width == 1080 && size.height == 1920) {
    return AVCaptureSessionPreset1920x1080;
  } else if (size.width == 720 && size.height == 1280) {
    return AVCaptureSessionPreset1280x720;
  } else if (size.width == 480 && size.height == 640) {
    return AVCaptureSessionPreset640x480;
  } else if (size.width == 288 && size.height == 352) {
    return AVCaptureSessionPreset352x288;
  } else {
    // Default to HD
    return AVCaptureSessionPreset1280x720;
  }
}

+ (NSArray *)captureFormatsForDevice:(AVCaptureDevice *)device  {
  NSMutableArray *qualities = [[NSMutableArray alloc] init];
  NSArray<AVCaptureDeviceFormat *>* formats = [device formats];
  for(int i = 0; i < formats.count; i++) {
    AVCaptureDeviceFormat *format = formats[i];
    [qualities addObject:
       [PreviewSize makeWithWidth:[NSNumber numberWithInt:CMVideoFormatDescriptionGetDimensions(format.formatDescription).width] height:[NSNumber numberWithInt:CMVideoFormatDescriptionGetDimensions(format.formatDescription).height]]
    ];
  }
  return qualities;
}

@end
