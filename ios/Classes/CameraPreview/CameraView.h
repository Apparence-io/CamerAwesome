//
//  CameraView.h
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <libkern/OSAtomic.h>
#import <CoreMotion/CoreMotion.h>
#import <Foundation/Foundation.h>

#import "CameraSensor.h"
#import "CaptureModes.h"
#import "CameraFlash.h"
#import "CameraQualities.h"
#import "CameraPictureController.h"
#import "CameraPermissions.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraView : NSObject<FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate>

@property(readonly, nonatomic) AVCaptureSession *captureSession;
@property(readonly, nonatomic) AVCaptureDevice *captureDevice;
@property(readonly, nonatomic) CMMotionManager *motionManager;
@property(readonly, nonatomic) AVCaptureInput *captureVideoInput;
@property(readonly, nonatomic) AVCaptureConnection *captureConnection;
@property(readonly, nonatomic) AVCaptureVideoDataOutput *captureVideoOutput;
@property(readonly, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property(readonly, nonatomic) AVCapturePhotoOutput *capturePhotoOutput;
@property(readonly, nonatomic) UIDeviceOrientation deviceOrientation;
@property(readonly, nonatomic) AVCaptureFlashMode flashMode;
@property(readonly, nonatomic) AVCaptureTorchMode torchMode;
@property(readonly, nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property(readonly, nonatomic) AVAssetWriter *videoWriter;
@property(readonly, nonatomic) AVAssetWriterInput *videoWriterInput;
@property(readonly, nonatomic) AVAssetWriterInput *audioWriterInput;
@property(readonly, nonatomic) AVAssetWriterInputPixelBufferAdaptor *videoAdaptor;
@property(assign, nonatomic) CMTime lastVideoSampleTime;
@property(assign, nonatomic) CMTime lastAudioSampleTime;
@property(assign, nonatomic) CMTime videoTimeOffset;
@property(assign, nonatomic) CMTime audioTimeOffset;
@property(readonly, nonatomic) CameraSensor cameraSensor;
@property(readonly, nonatomic) CaptureModes captureMode;
@property(readonly, nonatomic) FlutterResult result;
@property(readonly, nonatomic) NSString *currentPresset;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@property(readonly, nonatomic) CGSize currentPreviewSize;
@property(readonly, nonatomic) bool isRecording;
@property(readonly, nonatomic) bool enableAudio;
@property(readonly, nonatomic) bool streamImages;
@property(readonly, nonatomic) bool isAudioSetup;
@property(readonly, nonatomic) bool videoIsDisconnected;
@property(readonly, nonatomic) bool audioIsDisconnected;
@property(nonatomic) FlutterEventSink orientationEventSink;
@property(nonatomic) FlutterEventSink videoRecordingEventSink;
@property(nonatomic) FlutterEventSink imageStreamEventSink;
@property(nonatomic, copy) void (^onFrameAvailable)(void);
    
- (instancetype)initWithCameraSensor:(CameraSensor)sensor
                        streamImages:(BOOL)streamImages
                         captureMode:(CaptureModes)captureMode
                              result:(nonnull FlutterResult)result
                       dispatchQueue:(dispatch_queue_t)dispatchQueue
                           messenger:(NSObject<FlutterBinaryMessenger> *)messenger
                    orientationEvent:(FlutterEventSink)orientationEventSink
                 videoRecordingEvent:(FlutterEventSink)videoRecordingEventSink
                    imageStreamEvent:(FlutterEventSink)imageStreamEventSink;
- (void)setImageStreamEventSink:(FlutterEventSink _Nonnull)imageStreamEventSink;
- (void)setVideoRecordingEventSink:(FlutterEventSink _Nonnull)videoRecordingEventSink;
- (void)setOrientationEventSink:(FlutterEventSink _Nonnull)orientationEventSink;
- (void)setPreviewSize:(CGSize)previewSize;
- (void)setFlashMode:(CameraFlashMode)flashMode;
- (void)setCaptureMode:(CaptureModes)captureMode;
- (void)setRecordingAudioMode:(bool)enableAudio;
- (void)refresh;
- (void)start;
- (void)stop;
- (void)takePictureAtPath:(NSString *)path;
- (void)recordVideoAtPath:(NSString *)path;
- (void)stopRecordingVideo;
- (void)instantFocus;
- (void)dispose;
- (void)setResult:(FlutterResult _Nonnull)result;
- (void)setSensor:(CameraSensor)sensor;
- (void)setZoom:(float)value;
- (CGFloat)getMaxZoom;
- (CGSize)getEffectivPreviewSize;

@end

NS_ASSUME_NONNULL_END
