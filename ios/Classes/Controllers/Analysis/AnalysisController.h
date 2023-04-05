//
//  AnalysisController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 04/04/2023.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "Pigeon.h"

NS_ASSUME_NONNULL_BEGIN

@interface AnalysisController : NSObject

+ (void)bgra8888toJpegBgra8888image:(nonnull AnalysisImageWrapper *)bgra8888image jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion;
+ (void)nv21toJpegNv21Image:(nonnull AnalysisImageWrapper *)nv21Image jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion;
+ (void)yuv420toJpegYuvImage:(nonnull AnalysisImageWrapper *)yuvImage jpegQuality:(nonnull NSNumber *)jpegQuality completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion;
+ (void)yuv420toNv21YuvImage:(nonnull AnalysisImageWrapper *)yuvImage completion:(nonnull void (^)(AnalysisImageWrapper * _Nullable, FlutterError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
