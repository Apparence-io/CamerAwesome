//
//  CameraView.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraView.h"

@implementation CameraView

- (instancetype)initWithCameraSensor:(CameraSensor) sensor {
    self = [super init];
    
    _captureSession = [[AVCaptureSession alloc] init];
    _captureDevice = [AVCaptureDevice deviceWithUniqueID:[self selectAvailableCamera:sensor]];
    
    NSError *localError = nil;
    _captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&localError];
    _captureVideoOutput = [AVCaptureVideoDataOutput new];
    _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

    _captureConnection = [AVCaptureConnection connectionWithInputPorts:_captureVideoInput.ports output:_captureVideoOutput];
    [self updatePreviewOrientation];
    
    _captureOutput = [[AVCaptureMetadataOutput alloc] init];
    _captureOutput.metadataObjectTypes = _captureOutput.availableMetadataObjectTypes;
    [_captureSession addInputWithNoConnections:_captureVideoInput];
    [_captureSession addOutputWithNoConnections:_captureVideoOutput];
    [_captureSession addOutput:_captureOutput];

    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    [_captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_captureOutput setMetadataObjectTypes:@[AVMetadataObjectTypeAztecCode,
                                             AVMetadataObjectTypeCode39Code,
                                             AVMetadataObjectTypeCode93Code,
                                             AVMetadataObjectTypeCode128Code,
                                             AVMetadataObjectTypeDataMatrixCode,
                                             AVMetadataObjectTypeEAN8Code,
                                             AVMetadataObjectTypeEAN13Code,
                                             AVMetadataObjectTypeITF14Code,
                                             AVMetadataObjectTypePDF417Code,
                                             AVMetadataObjectTypeQRCode,
                                             AVMetadataObjectTypeUPCECode]];
    [_captureSession addConnection:_captureConnection];
    _capturePhotoOutput = [AVCapturePhotoOutput new];
    [_capturePhotoOutput setHighResolutionCaptureEnabled:YES];
    [_captureSession addOutput:_capturePhotoOutput];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    return self;
}

- (void)orientationChanged:(NSNotification *)notification {
    [self updatePreviewOrientation];
}

// TODO: Install observer on subview
- (void) handlePinchToZoomRecognizer:(UIPinchGestureRecognizer*)pinchRecognizer {
    const CGFloat pinchZoomScaleFactor = 2.0;

    if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
        NSError *error = nil;
        if ([_captureDevice lockForConfiguration:&error]) {
            _captureDevice.videoZoomFactor = 1.0 + pinchRecognizer.scale * pinchZoomScaleFactor;
            [_captureDevice unlockForConfiguration];
        } else {
            NSLog(@"error: %@", error);
        }
    }
}

- (void)updatePreviewOrientation {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

    AVCaptureVideoOrientation previewOrientation;
    
    
    if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        previewOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
        previewOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    [_captureConnection setVideoOrientation:previewOrientation];
}

// TODO: Call from Dart
- (void)dispose {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)setPreviewSize:(CGSize)previewSize {
    NSString *selectedPresset = [CameraQualities selectVideoCapturePressetWidth:previewSize];
    _previewSize = previewSize;
    _captureSession.sessionPreset = selectedPresset;
}

- (void)start {
    [_captureSession startRunning];
}

- (void)stop {
    [_captureSession stopRunning];
}

- (void)setFlashMode:(CameraFlashMode)flashMode {
    if (![_captureDevice hasFlash]) {
        // TODO: Error
    }
    
    NSError *error;
    [_captureDevice lockForConfiguration:&error];
    if (error != nil) {
        // TODO: Error
    }
    [_captureDevice setTorchMode:AVCaptureTorchModeOn];
    
    switch (flashMode) {
        case None:
            _torchMode = AVCaptureTorchModeOff;
            _flashMode = AVCaptureFlashModeOff;
            break;
        case Auto:
            _torchMode = AVCaptureTorchModeAuto;
            _flashMode = AVCaptureFlashModeAuto;
            break;
        case Always:
            _torchMode = AVCaptureTorchModeOn;
            _flashMode = AVCaptureFlashModeOn;
            break;
        default:
            _torchMode = AVCaptureTorchModeOff;
            _flashMode = AVCaptureFlashModeOff;
            break;
    }
    [_captureDevice setTorchMode:_torchMode];
    
    [_captureDevice unlockForConfiguration];
}

- (void)instantFocusWithResult:(nonnull FlutterResult)result {
    NSError *error;
    
    // Get center point of the preview size
    double focus_x = _previewSize.width / 2;
    double focus_y = _previewSize.height / 2;

    CGPoint thisFocusPoint = [_previewLayer captureDevicePointOfInterestForPoint:CGPointMake(focus_x, focus_y)];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [_captureDevice isFocusPointOfInterestSupported]) {
        if ([_captureDevice lockForConfiguration:&error]) {
            
            if (error != nil) {
                result([FlutterError errorWithCode:@"FOCUS_ERROR" message:@"impossible to set focus point" details:@""]);
            }
            
            [_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [_captureDevice setFocusPointOfInterest:thisFocusPoint];

            [_captureDevice unlockForConfiguration];
        }
    }
}

- (void)takePictureAtPath:(NSString *)path size:(CGSize)size andResult:(nonnull FlutterResult)result {
    // Get device orientation from device
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    // Instanciate camera picture obj
    CameraPicture *cameraPicture = [[CameraPicture alloc] initWithPath:path
                                                           orientation:deviceOrientation
                                                           captureSize:size
                                                                result:result
                                                              callback:^{
                                                                // If flash mode is always on, restore it back after photo is taken
                                                                if (self->_torchMode == AVCaptureTorchModeOn) {
                                                                    [self->_captureDevice lockForConfiguration:nil];
                                                                    [self->_captureDevice setTorchMode:AVCaptureTorchModeOn];
                                                                    [self->_captureDevice unlockForConfiguration];
                                                                }
                                                            }];
    
    // Create settings instance
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    [settings setFlashMode:_flashMode];

    [_capturePhotoOutput capturePhotoWithSettings:settings
                                         delegate:cameraPicture];
    
    
    
}

- (NSString *)selectAvailableCamera:(CameraSensor)sensor {
    NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                         discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                                               mediaType:AVMediaTypeVideo
                                                                                position:AVCaptureDevicePositionUnspecified];
    devices = discoverySession.devices;
    
    NSInteger cameraType = (sensor == Front) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    for (AVCaptureDevice *device in devices) {
        if ([device position] == cameraType) {
            return [device uniqueID];
        }
    }
    return nil;
}

# pragma mark - Camera Delegates

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (output == _captureVideoOutput) {
           CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
           CFRetain(newBuffer);
           CVPixelBufferRef old = _latestPixelBuffer;
           while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
               old = _latestPixelBuffer;
           }
           if (old != nil) {
               CFRelease(old);
           }
           if (_onFrameAvailable) {
               _onFrameAvailable();
           }
       }
}

# pragma mark - Flutter Delegates

- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    
    return pixelBuffer;
}

@end
