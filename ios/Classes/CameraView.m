//
//  CameraView.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraView.h"

@implementation CameraView

- (instancetype)initWithCameraSensor:(CameraSensor)sensor andResult:(nonnull FlutterResult)result {
    self = [super init];
    
    _result = result;
    
    // Creating capture session
    _captureSession = [[AVCaptureSession alloc] init];
    
    // Creating video output
    _captureVideoOutput = [AVCaptureVideoDataOutput new];
    _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_captureSession addOutputWithNoConnections:_captureVideoOutput];

    // Creating input device
    [self initCamera:sensor];
    
    [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
    
    // By default enable auto flash mode
    _flashMode = AVCaptureFlashModeAuto;
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    _cameraSensor = sensor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [self updatePreviewOrientation];
    
    return self;
}

- (void)initCamera:(CameraSensor)sensor {
    NSError *error;
    _captureDevice = [AVCaptureDevice deviceWithUniqueID:[self selectAvailableCamera:sensor]];
    _captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (error != nil) {
        _result([FlutterError errorWithCode:@"CANNOT_OPEN_CAMERA" message:@"can't attach device to input" details:[error localizedDescription]]);
    }
    
    // Set preset
    if (sensor == Back) {
        [self setPreviewSize:_previewSize];
    } else {
        [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    
    // Create connection
    _captureConnection = [AVCaptureConnection connectionWithInputPorts:_captureVideoInput.ports
                                                                output:_captureVideoOutput];
    
    // Attaching to session
    [_captureSession addInputWithNoConnections:_captureVideoInput];
    [_captureSession addConnection:_captureConnection];
    
    // Creating photo output
    _capturePhotoOutput = [AVCapturePhotoOutput new];
    [_capturePhotoOutput setHighResolutionCaptureEnabled:YES];
    [_captureSession addOutput:_capturePhotoOutput];
    
    // Mirror the preview only on portrait mode
    [_captureConnection setAutomaticallyAdjustsVideoMirroring:NO];
    [_captureConnection setVideoMirrored:(_cameraSensor == Back)];
}

- (void)orientationChanged:(NSNotification *)notification {
    [self updatePreviewOrientation];
}

- (void)updatePreviewOrientation {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

    AVCaptureVideoOrientation previewOrientation;
    if (_cameraSensor == Back) {
        if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
            previewOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        } else {
            previewOrientation = AVCaptureVideoOrientationPortrait;
        }
    } else {
        if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
            previewOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
            previewOrientation = AVCaptureVideoOrientationPortrait;
        } else {
            previewOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    
    [_captureConnection setVideoOrientation:previewOrientation];
}

- (void)setResult:(nonnull FlutterResult)result {
    _result = result;
}

- (void)dispose {
    [self stop];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)setPreviewSize:(CGSize)previewSize {
    NSString *selectedPresset = [CameraQualities selectVideoCapturePresset:previewSize session:_captureSession];
    _previewSize = previewSize;
    _captureSession.sessionPreset = selectedPresset;
}

- (void)start {
    [_captureSession startRunning];
}

- (void)stop {
    [_captureSession stopRunning];
}

- (void)flipCamera {
    CameraSensor sensor = (_cameraSensor == Front) ? Back : Front;
    
    // First remove all input & output
    [_captureSession beginConfiguration];
    AVCaptureDeviceInput *oldInput = [_captureSession.inputs firstObject];
    [_captureSession removeInput:oldInput];
    [_captureSession removeOutput:_capturePhotoOutput];
    [_captureSession removeConnection:_captureConnection];
    
    // Init the camera with the selected sensor
    [self initCamera:sensor];

    [_captureSession commitConfiguration];
    
    [self updatePreviewOrientation];
    
    _cameraSensor = sensor;
}

- (void)setFlashMode:(CameraFlashMode)flashMode {
//    if (![_captureDevice hasFlash]) {
//        _result([FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"flash is not supported on this device" details:@""]);
//    }
    
    NSError *error;
    [_captureDevice lockForConfiguration:&error];
    if (error != nil) {
        _result([FlutterError errorWithCode:@"FLASH_ERROR" message:@"impossible to change configuration" details:@""]);
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
            _torchMode = AVCaptureTorchModeAuto;
            _flashMode = AVCaptureFlashModeAuto;
            break;
    }
    [_captureDevice setTorchMode:_torchMode];
    [_captureDevice unlockForConfiguration];
    
    _result(nil);
}

/// Trigger focus on device at the center of the preview
- (void)instantFocus {
    NSError *error;
    
    // Get center point of the preview size
    double focus_x = _previewSize.width / 2;
    double focus_y = _previewSize.height / 2;

    CGPoint thisFocusPoint = [_previewLayer captureDevicePointOfInterestForPoint:CGPointMake(focus_x, focus_y)];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [_captureDevice isFocusPointOfInterestSupported]) {
        if ([_captureDevice lockForConfiguration:&error]) {
            if (error != nil) {
                _result([FlutterError errorWithCode:@"FOCUS_ERROR" message:@"impossible to set focus point" details:@""]);
            }
            
            [_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [_captureDevice setFocusPointOfInterest:thisFocusPoint];

            [_captureDevice unlockForConfiguration];
        }
    }
}

/// Take the picture into the given path
- (void)takePictureAtPath:(NSString *)path {

    // Get device orientation from device
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
    // Instanciate camera picture obj
    CameraPicture *cameraPicture = [[CameraPicture alloc] initWithPath:path
                                                           orientation:deviceOrientation
                                                                sensor:_cameraSensor
                                                                result:_result
                                                              callback:^{
                                                                // If flash mode is always on, restore it back after photo is taken
                                                                if (self->_torchMode == AVCaptureTorchModeOn) {
                                                                    [self->_captureDevice lockForConfiguration:nil];
                                                                    [self->_captureDevice setTorchMode:AVCaptureTorchModeOn];
                                                                    [self->_captureDevice unlockForConfiguration];
                                                                }

                                                                self->_result(nil);
                                                            }];
    
    // Create settings instance
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    [settings setFlashMode:_flashMode];

    [_capturePhotoOutput capturePhotoWithSettings:settings
                                         delegate:cameraPicture];
}

/// Get the first available camera on device (front or rear)
- (NSString *)selectAvailableCamera:(CameraSensor)sensor {
    NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                         discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
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

/// Used to copy pixels to in-memory buffer
- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    
    return pixelBuffer;
}

@end
