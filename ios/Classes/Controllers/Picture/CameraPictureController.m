//
//  CameraPicture.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraPictureController.h"
#import "ExifContainer.h"
#import "NSData+Exif.h"

@implementation CameraPictureController {
  CameraPictureController *selfReference;
}

- (instancetype)initWithPath:(NSString *)path
                 orientation:(NSInteger)orientation
                      sensor:(CameraSensor)sensor
             saveGPSLocation:(bool)saveGPSLocation
                 aspectRatio:(AspectRatio)aspectRatio
                      result:(FlutterResult)result
                    callback:(OnPictureTaken)callback {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  _path = path;
  _result = result;
  _orientation = orientation;
  _completionBlock = callback;
  _sensor = sensor;
  _saveGPSLocation = saveGPSLocation;
  
  if (aspectRatio == Ratio4_3) {
    _aspectRatio = 4.0/3.0;
  } else if(aspectRatio == Ratio16_9) {
    _aspectRatio = 16.0/9.0;
  } else {
    _aspectRatio = 1;
  }
  
  selfReference = self;
  return self;
}

- (NSData *)writeMetadataIntoImageData:(NSData *)imageData metadata:(NSMutableDictionary *)metadata {
  // create an imagesourceref
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
  
  // this is the type of image (e.g., public.jpeg)
  CFStringRef UTI = CGImageSourceGetType(source);
  
  // create a new data object and write the new image into it
  NSMutableData *dest_data = [NSMutableData data];
  CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1, NULL);
  if (!destination) {
    NSLog(@"Error: Could not create image destination");
  }
  // add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
  CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef) metadata);
  BOOL success = NO;
  success = CGImageDestinationFinalize(destination);
  if (!success) {
    NSLog(@"Error: Could not create data from image destination");
  }
  CFRelease(destination);
  CFRelease(source);
  return dest_data;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer
previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer
     resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
      bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings
                error:(NSError *)error {
#pragma clang diagnostic pop

  selfReference = nil;
  if (error) {
    _result([FlutterError errorWithCode:@"CAPTURE ERROR" message:error.description details:@""]);
    return;
  }
  
  // Add exif data
  ExifContainer *container = [[ExifContainer alloc] init];
  [container addCreationDate:[NSDate date]];
  
  // Save GPS location only if provided
  if (_saveGPSLocation) {
    CLLocationManager *locationManager = [CLLocationManager new];
    CLLocation *location = [locationManager location];
    [container addLocation:location];
  }
  
  // we ignore this error because plugin can only be installed on iOS 11+
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                             previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  #pragma clang diagnostic pop
  
  UIImage *image = [UIImage imageWithCGImage:[UIImage imageWithData:data].CGImage
                                       scale:1.0
                                 orientation:[self getJpegOrientation]];
  float originalWidth = image.size.width;
  float originalHeight = image.size.height;
  
  float originalImageAspectRatio = originalWidth / originalHeight;
  
  float outputWidth = originalWidth;
  float outputHeight = originalHeight;
  if (originalImageAspectRatio != _aspectRatio) {
    if (UIDeviceOrientationIsLandscape(_orientation)) {
      if (originalImageAspectRatio > _aspectRatio) {
        outputWidth = originalHeight * _aspectRatio;
      } else if (originalImageAspectRatio < _aspectRatio) {
        outputHeight = originalWidth / _aspectRatio;
      }
    } else {
      if (originalImageAspectRatio > _aspectRatio) {
        outputWidth = originalHeight / _aspectRatio;
      } else if (originalImageAspectRatio < _aspectRatio) {
        outputHeight = originalWidth * _aspectRatio;
      }
    }
    
    double refWidth = CGImageGetWidth(image.CGImage);
    double refHeight = CGImageGetHeight(image.CGImage);
    
    double x = (refWidth - outputWidth) / 2.0;
    double y = (refHeight - outputHeight) / 2.0;

    CGRect cropRect = CGRectMake(x, y, outputHeight, outputWidth);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);

    image = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:[self getJpegOrientation]];
    CGImageRelease(imageRef);
  }
  
  
  // TODO: crop image to aspect ratio
  
  NSData *imageWithExif = [UIImageJPEGRepresentation(image, 1.0) addExif:container];
  
  bool success = [imageWithExif writeToFile:_path atomically:YES];
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
