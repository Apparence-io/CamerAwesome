//
//  CameraPreview.h
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#include <stdatomic.h>

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>

#import "MotionController.h"
#import "LocationController.h"
#import "VideoController.h"
#import "ImageStreamController.h"
#import "CameraSensor.h"
#import "CaptureModes.h"
#import "CameraFlash.h"
#import "CameraQualities.h"
#import "CameraPictureController.h"
#import "PermissionsController.h"
#import "AspectRatio.h"
#import "CameraSensorType.h"
#import "PhysicalButtonController.h"
#import "InputAnalysisImageFormat.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraPreview : NSObject<FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate>

@property(readonly, nonatomic) AVCaptureSession *captureSession;
@property(readonly, nonatomic) AVCaptureDevice *captureDevice;
@property(readonly, nonatomic) AVCaptureInput *captureVideoInput;
@property(readonly, nonatomic) AVCaptureConnection *captureConnection;
@property(readonly, nonatomic) AVCaptureVideoDataOutput *captureVideoOutput;
@property(readonly, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property(readonly, nonatomic) AVCapturePhotoOutput *capturePhotoOutput;
@property(readonly, nonatomic) UIDeviceOrientation deviceOrientation;
@property(readonly, nonatomic) AVCaptureFlashMode flashMode;
@property(readonly, nonatomic) AVCaptureTorchMode torchMode;
@property(readonly, nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property(readonly, nonatomic) CameraSensor cameraSensor;
@property(readonly, nonatomic) NSString *captureDeviceId;
@property(readonly, nonatomic) CaptureModes captureMode;
@property(readonly, nonatomic) NSString *currentPresset;
@property(readonly, nonatomic) AspectRatio aspectRatio;
@property(readonly, nonatomic) bool saveGPSLocation;
@property(readonly, nonatomic) bool mirrorFrontCamera;
@property(readonly) _Atomic(CVPixelBufferRef) latestPixelBuffer;
@property(readonly, nonatomic) CGSize currentPreviewSize;
@property(readonly, nonatomic) ImageStreamController *imageStreamController;
@property(readonly, nonatomic) MotionController *motionController;
@property(readonly, nonatomic) LocationController *locationController;
@property(readonly, nonatomic) VideoController *videoController;
@property(readonly, nonatomic) PhysicalButtonController *physicalButtonController;
@property(readonly, copy) void (^completion)(NSNumber * _Nullable, FlutterError * _Nullable);
@property(nonatomic, copy) void (^onFrameAvailable)(void);

- (instancetype)initWithCameraSensor:(CameraSensor)sensor
                        streamImages:(BOOL)streamImages
                   mirrorFrontCamera:(BOOL)mirrorFrontCamera
                enablePhysicalButton:(BOOL)enablePhysicalButton
                     aspectRatioMode:(AspectRatio)aspectRatioMode
                         captureMode:(CaptureModes)captureMode
                          completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion
                       dispatchQueue:(dispatch_queue_t)dispatchQueue;
- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setImageStreamEvent:(FlutterEventSink)imageStreamEventSink;
- (void)setOrientationEventSink:(FlutterEventSink)orientationEventSink;
- (void)setPhysicalButtonEventSink:(FlutterEventSink)physicalButtonEventSink;
- (void)setFlashMode:(CameraFlashMode)flashMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setCaptureMode:(CaptureModes)captureMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setCameraPresset:(CGSize)currentPreviewSize;
- (void)setRecordingAudioMode:(bool)enableAudio completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)pauseVideoRecording;
- (void)resumeVideoRecording;
- (void)receivedImageFromStream;
- (void)setAspectRatio:(AspectRatio)ratio;
- (void)setExifPreferencesGPSLocation:(bool)gpsLocation completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)refresh;
- (void)start;
- (void)stop;
- (void)takePictureAtPath:(NSString *)path completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion;
- (void)recordVideoAtPath:(NSString *)path withOptions:(VideoOptions *)options completion:(nonnull void (^)(FlutterError * _Nullable))completion;
- (void)stopRecordingVideo:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion;
- (void)focusOnPoint:(CGPoint)position preview:(CGSize)preview error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)dispose;
- (NSArray *)getSensors:(AVCaptureDevicePosition)position;
- (void)setSensor:(CameraSensor)sensor deviceId:(NSString *)captureDeviceId;
- (void)setZoom:(float)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setMirrorFrontCamera:(bool)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (CGFloat)getMaxZoom;
- (CGSize)getEffectivPreviewSize;
- (void)setUpCaptureSessionForAudioError:(nonnull void (^)(NSError *))error;
- (void)setBrightness:(NSNumber *)brightness error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
@end

NS_ASSUME_NONNULL_END
