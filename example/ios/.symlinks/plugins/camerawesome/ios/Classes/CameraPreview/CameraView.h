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

@interface CameraView : NSObject<FlutterTexture, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

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
@property(readonly, nonatomic) FlutterResult result;
@property(readonly, nonatomic) NSString *currentPresset;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@property(readonly, nonatomic) CGSize currentPreviewSize;
@property(readonly, nonatomic) bool isRecording;
@property(readonly, nonatomic) bool enableAudio;
@property(readonly, nonatomic) bool isAudioSetup;
@property(readonly, nonatomic) bool videoIsDisconnected;
@property(readonly, nonatomic) bool audioIsDisconnected;
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic, copy) void (^onFrameAvailable)(void);
    
- (instancetype)initWithCameraSensor:(CameraSensor)sensor
                              result:(nonnull FlutterResult)result
                           messenger:(NSObject<FlutterBinaryMessenger> *)messenger
                               event:(FlutterEventSink)eventSink;
- (void)setPreviewSize:(CGSize)previewSize;
- (void)setFlashMode:(CameraFlashMode)flashMode;
- (void)start;
- (void)stop;
- (void)takePictureAtPath:(NSString *)path;
- (void)recordVideoAtPath:(NSString *)path;
- (void)stopRecordingVideo;
- (void)instantFocus;
- (void)dispose;
- (void)setResult:(nonnull FlutterResult)result;
- (void)setSensor:(CameraSensor)sensor;
- (void)setZoom:(float)value;
- (CGFloat)getMaxZoom;
- (CGSize)getEffectivPreviewSize;

@end

NS_ASSUME_NONNULL_END
