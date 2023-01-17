//
//  CameraQualities.h
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import <AVFoundation/AVFoundation.h>
#import "Pigeon.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraQualities : NSObject

+ (AVCaptureSessionPreset)selectVideoCapturePresset:(CGSize)size session:(AVCaptureSession *)session device:(AVCaptureDevice *)device;
+ (AVCaptureSessionPreset)selectVideoCapturePresset:(AVCaptureSession *)session device:(AVCaptureDevice *)device;
+ (CGSize)getSizeForPresset:(NSString *)presset;
+ (NSArray *)captureFormatsForDevice:(AVCaptureDevice *)device;

@end

NS_ASSUME_NONNULL_END
