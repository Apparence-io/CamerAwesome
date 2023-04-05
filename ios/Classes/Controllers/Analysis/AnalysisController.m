//
//  AnalysisController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 04/04/2023.
//

#import "AnalysisController.h"

@implementation AnalysisController

+ (void)bgra8888toJpegBgra8888image:(nonnull AnalysisImageWrapper *)bgra8888image jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  NSData *bgra8888Data = bgra8888image.bytes.data;
  CFDataRef cfData = (__bridge CFDataRef)bgra8888Data;
  
  CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(cfData);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGImageRef cgImage = CGImageCreate(bgra8888image.width.intValue,
                                     bgra8888image.height.intValue,
                                     8,
                                     32,
                                     [bgra8888image.planes.firstObject.bytesPerRow intValue],
                                     colorSpace,
                                     kCGBitmapByteOrder32Big |
                                     kCGImageAlphaPremultipliedLast,
                                     dataProvider,
                                     NULL,
                                     true,
                                     kCGRenderingIntentDefault);
  
  UIImage *image = [UIImage imageWithCGImage:cgImage];
  NSData *jpegData = UIImageJPEGRepresentation(image, [jpegQuality floatValue]);
  
  
  FlutterStandardTypedData *dataFlutter = [FlutterStandardTypedData typedDataWithBytes:jpegData];
  
  
  AnalysisImageWrapper *jpegImage = [AnalysisImageWrapper makeWithFormat:AnalysisImageFormatJpeg
                                                                   bytes:dataFlutter
                                                                   width:bgra8888image.width
                                                                  height:bgra8888image.height
                                                                  planes:bgra8888image.planes
                                                                cropRect:bgra8888image.cropRect
                                                                rotation:bgra8888image.rotation];
  
  completion(jpegImage, nil);
  
  CGColorSpaceRelease(colorSpace);
  CGImageRelease(cgImage);
  CGDataProviderRelease(dataProvider);
}

+ (void)nv21toJpegNv21Image:(nonnull AnalysisImageWrapper *)nv21Image jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  completion(nil, [FlutterError errorWithCode:@"NOT_SUPPORTED" message:@"this format is currently not supported on iOS" details:nil]);
}

+ (void)yuv420toJpegYuvImage:(nonnull AnalysisImageWrapper *)yuvImage jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  completion(nil, [FlutterError errorWithCode:@"NOT_SUPPORTED" message:@"this format is currently not supported on iOS" details:nil]);
}

+ (void)yuv420toNv21YuvImage:(nonnull AnalysisImageWrapper *)yuvImage completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion {
  completion(nil, [FlutterError errorWithCode:@"NOT_SUPPORTED" message:@"this format is currently not supported on iOS" details:nil]);
}

@end
