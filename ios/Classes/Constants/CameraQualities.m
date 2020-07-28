//
//  CameraQualities.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraQualities.h"

@implementation CameraQualities

// TODO: Improve by getting width & height from constants dict
+ (NSString *)selectVideoCapturePresset:(CGSize)size session:(AVCaptureSession *)session {
    NSString *preset;
    if (size.width == 3840 && size.height == 2160) {
        if (@available(iOS 9.0, *)) {
            preset = [CameraQualities setPresetFallback:AVCaptureSessionPreset3840x2160 session:session];
        } else {
            preset = [CameraQualities setPresetFallback:AVCaptureSessionPreset1920x1080 session:session];
        }
    } else if (size.width == 1920 && size.height == 1080) {
        preset = [CameraQualities setPresetFallback:AVCaptureSessionPreset1920x1080 session:session];
    } else if (size.width == 1280 && size.height == 720) {
        preset = [CameraQualities setPresetFallback:AVCaptureSessionPreset1280x720 session:session];
    } else if (size.width == 640 && size.height == 480) {
        preset = [CameraQualities setPresetFallback:AVCaptureSessionPreset640x480 session:session];
    } else if (size.width == 352 && size.height == 288) {
        preset = [CameraQualities setPresetFallback:AVCaptureSessionPreset352x288 session:session];
    } else {
        // Default to photo mode
        preset = AVCaptureSessionPresetPhoto;
    }
    
    return preset;
}

+ (NSString *)setPresetFallback:(AVCaptureSessionPreset)preset session:(AVCaptureSession *)session {
    if ([session canSetSessionPreset:preset]) {
        return preset;
    } else {
        return AVCaptureSessionPresetPhoto;
    }
}

@end
