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
#import "CameraFlash.h"
#import "CameraQualities.h"
#import "CameraPicture.h"
#import "CameraPermissions.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraView : NSObject<FlutterTexture, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property(readonly, nonatomic) AVCaptureMetadataOutput *captureOutput;
@property(readonly, nonatomic) AVCaptureSession *captureSession;
@property(readonly, nonatomic) AVCaptureDevice *captureDevice;
@property(readonly, nonatomic) AVCaptureInput *captureVideoInput;
@property(readonly, nonatomic) AVCaptureConnection *captureConnection;
@property(readonly, nonatomic) AVCaptureVideoDataOutput *captureVideoOutput;
@property(readonly, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property(readonly, nonatomic) AVCapturePhotoOutput *capturePhotoOutput;
@property(readonly, nonatomic) AVCaptureFlashMode flashMode;
@property(readonly, nonatomic) AVCaptureTorchMode torchMode;
@property(readonly, nonatomic) CameraSensor cameraSensor;
@property(readonly, nonatomic) FlutterResult result;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@property(readonly, nonatomic) CGSize previewSize;
@property(nonatomic) FlutterEventSink eventSink;
@property(nonatomic, copy) void (^onFrameAvailable)(void);
    
- (instancetype)initWithCameraSensor:(CameraSensor)sensor andResult:(nonnull FlutterResult)result;
- (void)setPreviewSize:(CGSize)previewSize;
- (void)setFlashMode:(CameraFlashMode)flashMode;
- (void)start;
- (void)stop;
- (void)takePictureAtPath:(NSString *)path;
- (void)instantFocus;
- (void)dispose;
- (void)setResult:(nonnull FlutterResult)result;
- (void)flipCamera;

@end

NS_ASSUME_NONNULL_END
