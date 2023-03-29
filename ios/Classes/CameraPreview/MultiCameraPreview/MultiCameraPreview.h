//
//  MultiCameraPreview.h
//  camerawesome
//
//  Created by Dimitri Dessus on 28/03/2023.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MultiCameraPreview.h"
#import "CameraPreviewTexture.h"
#import "CameraQualities.h"

NS_ASSUME_NONNULL_BEGIN

@interface MultiCameraPreview : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureMultiCamSession  *cameraSession;

// TODO: Store all of them in a dict
@property (nonatomic, strong) AVCaptureDeviceInput *frontDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *frontVideoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *frontPreviewLayer;

// TODO: Store all of them in a dict
@property (nonatomic, strong) AVCaptureDeviceInput *backDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *backVideoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *backPreviewLayer;
@property (nonatomic, strong) dispatch_queue_t dataOutputQueue;

// TODO: Store all of them in a dict
@property(nonatomic, nonatomic) NSMutableArray<CameraPreviewTexture *> *textures;

// TODO: Send an ID
@property(nonatomic, copy) void (^onPreviewFrameAvailable)(NSNumber * _Nullable);

- (instancetype)initWithSensors:(NSArray<Sensors *> *)sensors;
- (void)configSession:(NSArray<Sensors *> *)sensors;
- (void)start;
- (void)stop;
- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (CGSize)getEffectivPreviewSize;
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
