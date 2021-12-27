//
//  CameraPicture.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraPictureController.h"

@implementation CameraPictureController {
    CameraPictureController *selfReference;
}

- (instancetype)initWithPath:(NSString *)path
                 orientation:(NSInteger)orientation
                      sensor:(CameraSensor)sensor
                      result:(FlutterResult)result
                    callback:(OnPictureTaken)callback {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _path = path;
    _result = result;
    _orientation = orientation;
    _completionBlock = callback;
    _sensor = sensor;
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
    _result(nil);
}

- (UIImageOrientation)getJpegOrientation {
    switch (_orientation) {
        case UIDeviceOrientationPortrait:
            return (_sensor == Back) ? UIImageOrientationRight : UIImageOrientationLeftMirrored;
            break;
        case UIDeviceOrientationLandscapeRight:
            return (_sensor == Back) ? UIImageOrientationUp : UIImageOrientationDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            return (_sensor == Back) ? UIImageOrientationDown : UIImageOrientationUp;
            break;
        default:
            return UIImageOrientationLeft;
            break;
    }
}

@end
