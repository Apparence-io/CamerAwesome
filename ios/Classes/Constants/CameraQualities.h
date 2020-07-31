//
//  CameraQualities.h
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import <AVFoundation/AVFoundation.h>

#define kCameraQualities @[\
    @{\
        @"width": @3840,\
        @"height": @2160\
    },\
    @{\
        @"width": @1920,\
        @"height": @1080\
    },\
    @{\
        @"width": @1280,\
        @"height": @720\
    },\
    @{\
        @"width": @640,\
        @"height": @480\
    },\
    @{\
        @"width": @352,\
        @"height": @288\
    }\
]

NS_ASSUME_NONNULL_BEGIN

@interface CameraQualities : NSObject

+ (NSString *)selectVideoCapturePresset:(CGSize)size session:(AVCaptureSession *)session;
+ (NSString *)selectVideoCapturePresset:(AVCaptureSession *)session;
+ (CGSize)getSizeForPresset:(NSString *)presset;

@end

NS_ASSUME_NONNULL_END
