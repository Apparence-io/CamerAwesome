//
//  MultiCameraPreview.h
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

// #import "MultiCameraPreview.h"
#import "CameraPreviewTexture.h"
#import "CameraQualities.h"
#import "CameraDeviceInfo.h"
#import "CameraPictureController.h"
#import "MotionController.h"
#import "ImageStreamController.h"
#import "PhysicalButtonController.h"
#import "AspectRatio.h"
#import "LocationController.h"
#import "CameraFlash.h"
#import "CaptureModes.h"
#import "SensorUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface MultiCameraPreview : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureMultiCamSession  *cameraSession;

@property (nonatomic, strong) NSArray<PigeonSensor *> *sensors;
@property (nonatomic, strong) NSMutableArray<CameraDeviceInfo *> *devices;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property(readonly, nonatomic) AVCaptureFlashMode flashMode;
@property(readonly, nonatomic) AVCaptureTorchMode torchMode;
@property(readonly, nonatomic) AspectRatio aspectRatio;
@property(readonly, nonatomic) LocationController *locationController;
@property(readonly, nonatomic) MotionController *motionController;
@property(readonly, nonatomic) PhysicalButtonController *physicalButtonController;
@property(readonly, nonatomic) bool saveGPSLocation;
@property(readonly, nonatomic) bool mirrorFrontCamera;
@property(nonatomic, nonatomic) NSMutableArray<CameraPreviewTexture *> *textures;
@property(nonatomic, copy) void (^onPreviewFrameAvailable)(NSNumber * _Nullable);

- (instancetype)initWithSensors:(NSArray<PigeonSensor *> *)sensors mirrorFrontCamera:(BOOL)mirrorFrontCamera
           enablePhysicalButton:(BOOL)enablePhysicalButton
                aspectRatioMode:(AspectRatio)aspectRatioMode
                    captureMode:(CaptureModes)captureMode
                  dispatchQueue:(dispatch_queue_t)dispatchQueue;
- (void)configInitialSession:(NSArray<PigeonSensor *> *)sensors;
- (void)setSensors:(NSArray<PigeonSensor *> *)sensors;
- (void)setMirrorFrontCamera:(bool)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setBrightness:(NSNumber *)brightness error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setFlashMode:(CameraFlashMode)flashMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)focusOnPoint:(CGPoint)position preview:(CGSize)preview error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setZoom:(float)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)start;
- (void)stop;
- (void)refresh;
- (CGFloat)getMaxZoom;
- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (CGSize)getEffectivPreviewSize;
- (void)takePhotoSensors:(nonnull NSArray<PigeonSensor *> *)sensors paths:(nonnull NSArray<NSString *> *)paths completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion;
- (void)dispose;
- (void)setAspectRatio:(AspectRatio)ratio;
- (void)setExifPreferencesGPSLocation:(bool)gpsLocation completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)setOrientationEventSink:(FlutterEventSink)orientationEventSink;
- (void)setPhysicalButtonEventSink:(FlutterEventSink)physicalButtonEventSink;

@end

NS_ASSUME_NONNULL_END
