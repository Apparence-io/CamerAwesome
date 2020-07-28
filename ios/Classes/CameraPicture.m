//
//  CameraPicture.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraPicture.h"

@implementation CameraPicture {
  CameraPicture *selfReference;
}

- (instancetype)initWithPath:(NSString *)path
                 orientation:(NSInteger)orientation
                      result:(FlutterResult)result
                    callback:(OnPictureTaken)callback {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _path = path;
    _result = result;
    _orientation = orientation;
    _completionBlock = callback;
    selfReference = self;
    return self;
}

- (void)captureOutput:(AVCapturePhotoOutput *)output
    didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer
                previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer
                        resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
                         bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings
                                   error:(NSError *)error {
    selfReference = nil;
    if (error) {
        _result([FlutterError errorWithCode:@"" message:@"" details:@""]);
        return;
    }
    NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                               previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    UIImage *image = [UIImage imageWithCGImage:[UIImage imageWithData:data].CGImage
                                         scale:1.0
                                   orientation:[self getJpegOrientation]];

    bool success = [UIImageJPEGRepresentation(image, 1.0) writeToFile:_path atomically:YES];
    if (!success) {
        _result([FlutterError errorWithCode:@"IOError" message:@"unable to write file" details:nil]);
        return;
    }
    _completionBlock();
}

- (UIImageOrientation)getJpegOrientation {
    NSInteger sensorOrientation;
    
    if (_orientation == UIDeviceOrientationPortrait) {
        sensorOrientation = UIDeviceOrientationLandscapeLeft;
    } else if (_orientation == UIDeviceOrientationLandscapeRight) {
        sensorOrientation = UIDeviceOrientationPortrait;
    } else {
        sensorOrientation = UIDeviceOrientationLandscapeRight;
    }
    
    return sensorOrientation;
}

@end
