//
//  CameraQualities.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraQualities.h"

@implementation CameraQualities

// TODO: Improve by getting width & height from constants dict
+ (NSString *)selectVideoCapturePressetWidth:(CGSize)size {
    NSString *presset;
    if (size.width == 3840 && size.height == 2160) {
        if (@available(iOS 9.0, *)) {
            presset = AVCaptureSessionPreset3840x2160;
        } else {
            presset = AVCaptureSessionPreset1920x1080;
        }
    } else if (size.width == 1920 && size.height == 1080) {
        presset = AVCaptureSessionPreset1920x1080;
    } else if (size.width == 1280 && size.height == 720) {
        presset = AVCaptureSessionPreset1280x720;
    } else if (size.width == 640 && size.height == 480) {
        presset = AVCaptureSessionPreset640x480;
    } else if (size.width == 352 && size.height == 288) {
        presset = AVCaptureSessionPreset352x288;
    } else {
        // Default to low
        presset = AVCaptureSessionPreset352x288;
    }
    
    return presset;
}

@end
