//
//  CameraQualities.h
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import <AVFoundation/AVFoundation.h>

#define kCameraQualities @[\
    @{\
        @"width": @3840.0,\
        @"height": @2160.0\
    },\
    @{\
        @"width": @1920.0,\
        @"height": @1080.0\
    },\
    @{\
        @"width": @1280.0,\
        @"height": @720.0\
    },\
    @{\
        @"width": @640.0,\
        @"height": @480.0\
    },\
    @{\
        @"width": @352.0,\
        @"height": @288.0\
    }\
]

NS_ASSUME_NONNULL_BEGIN

@interface CameraQualities : NSObject

+ (NSString *)selectVideoCapturePresset:(CGSize)size session:(AVCaptureSession *)session;

@end

NS_ASSUME_NONNULL_END
