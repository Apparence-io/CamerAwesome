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
@property(nonatomic, nonatomic) CameraPreviewTexture *backPreviewTexture;
@property(nonatomic, nonatomic) CameraPreviewTexture *frontPreviewTexture;

// TODO: Send an ID
@property(nonatomic, copy) void (^onPreviewBackFrameAvailable)(void);
@property(nonatomic, copy) void (^onPreviewFrontFrameAvailable)(void);

- (void)configSession;
- (void)start;
- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (CGSize)getEffectivPreviewSize;

@end

NS_ASSUME_NONNULL_END
