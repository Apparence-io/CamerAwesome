//
//  CameraView.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraView.h"

@implementation CameraView

- (instancetype)initWithCameraSensor:(CameraSensor)sensor result:(nonnull FlutterResult)result messenger:(NSObject<FlutterBinaryMessenger> *)messenger event:(FlutterEventSink)eventSink {
    self = [super init];
    
    _result = result;
    _messenger = messenger;
    _eventSink = eventSink;

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
    
    // Creating motion detection
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 0.2f;
    [self startMyMotionDetect];
    
    return self;
}

- (void)startMyMotionDetect {
    // TODO: Add weakself
    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                        withHandler:^(CMDeviceMotion *data, NSError *error) {
        UIDeviceOrientation newOrientation;
        if(fabs(data.gravity.x) > fabs(data.gravity.y)) {
            // Landscape
            newOrientation = (data.gravity.x >= 0) ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationLandscapeRight;
        } else {
            // Portrait
            newOrientation = (data.gravity.y >= 0) ? UIDeviceOrientationPortraitUpsideDown : UIDeviceOrientationPortrait;
        }
        if (self->_deviceOrientation != newOrientation) {
            self->_deviceOrientation = newOrientation;
            
            NSString *orientationString;
            switch (newOrientation) {
                case UIDeviceOrientationLandscapeLeft:
                    orientationString = @"LANDSCAPE_LEFT";
                    break;
                case UIDeviceOrientationLandscapeRight:
                    orientationString = @"LANDSCAPE_RIGHT";
                    break;
                case UIDeviceOrientationPortrait:
                    orientationString = @"PORTRAIT_UP";
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    orientationString = @"PORTRAIT_DOWN";
                    break;
                default:
                    break;
            }
            if (self->_eventSink != nil) {
                self->_eventSink(orientationString);
            }
        }
    }];
}

- (void)initCamera:(CameraSensor)sensor {
    // Here we set a preset which wont crash the device before switching to front or back
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    NSError *error;
    _captureDevice = [AVCaptureDevice deviceWithUniqueID:[self selectAvailableCamera:sensor]];
    _captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (error != nil) {
        _result([FlutterError errorWithCode:@"CANNOT_OPEN_CAMERA" message:@"can't attach device to input" details:[error localizedDescription]]);
        return;
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
    [_captureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [self setCameraPresset:CGSizeMake(0, 0)];
}

- (void)setCameraPresset:(CGSize)currentPreviewSize {
    NSString *presetSelected;
    if (!CGSizeEqualToSize(CGSizeZero, currentPreviewSize)) {
        // Try to get the quality requested
        presetSelected = [CameraQualities selectVideoCapturePresset:currentPreviewSize session:_captureSession];
    } else {
        // Compute the best quality supported by the camera device
        presetSelected = [CameraQualities selectVideoCapturePresset:_captureSession];
    }
    [_captureSession setSessionPreset:presetSelected];
    _currentPresset = presetSelected;
    
    // Get preview size according to presset selected
    _currentPreviewSize = [CameraQualities getSizeForPresset:presetSelected];
}

- (CGSize)getEffectivPreviewSize {
    return _currentPreviewSize;
}

- (void)setResult:(nonnull FlutterResult)result {
    _result = result;
}

- (void)dispose {
    [self stop];
}

- (void)setPreviewSize:(CGSize)previewSize {
    [self setCameraPresset:previewSize];
}

- (void)start {
    [_captureSession startRunning];
}

- (void)stop {
    [_captureSession stopRunning];
}

- (void)setSensor:(CameraSensor)sensor {
    // First remove all input & output
    [_captureSession beginConfiguration];
    AVCaptureDeviceInput *oldInput = [_captureSession.inputs firstObject];
    [_captureSession removeInput:oldInput];
    [_captureSession removeOutput:_capturePhotoOutput];
    [_captureSession removeConnection:_captureConnection];

    // Init the camera with the selected sensor
    [self initCamera:sensor];

    [_captureSession commitConfiguration];

    _cameraSensor = sensor;
}

- (CGFloat)getMaxZoom {
    return _captureDevice.activeFormat.videoMaxZoomFactor;
}

- (void)setZoom:(float)value {
    CGFloat maxZoom = _captureDevice.activeFormat.videoMaxZoomFactor;
    CGFloat scaledZoom = value * (maxZoom - 1.0f) + 1.0f;
    
    NSError *error;
    if ([_captureDevice lockForConfiguration:&error]) {
        _captureDevice.videoZoomFactor = scaledZoom;
        [_captureDevice unlockForConfiguration];
    } else {
        _result([FlutterError errorWithCode:@"ZOOM_NOT_SET" message:@"can't set the zoom value" details:[error localizedDescription]]);
    }
}

- (void)setFlashMode:(CameraFlashMode)flashMode {
    if (![_captureDevice hasFlash]) {
        _result([FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"flash is not supported on this device" details:@""]);
        return;
    }
    
    if (_cameraSensor == Front) {
        _result([FlutterError errorWithCode:@"FLASH_UNSUPPORTED" message:@"can't set flash for portrait mode" details:@""]);
        return;
    }
    
    NSError *error;
    [_captureDevice lockForConfiguration:&error];
    if (error != nil) {
        _result([FlutterError errorWithCode:@"FLASH_ERROR" message:@"impossible to change configuration" details:@""]);
        return;
    }
    
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
    double focus_x = _currentPreviewSize.width / 2;
    double focus_y = _currentPreviewSize.height / 2;

    CGPoint thisFocusPoint = [_previewLayer captureDevicePointOfInterestForPoint:CGPointMake(focus_x, focus_y)];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [_captureDevice isFocusPointOfInterestSupported]) {
        if ([_captureDevice lockForConfiguration:&error]) {
            if (error != nil) {
                _result([FlutterError errorWithCode:@"FOCUS_ERROR" message:@"impossible to set focus point" details:@""]);
                return;
            }
            
            [_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            [_captureDevice setFocusPointOfInterest:thisFocusPoint];

            [_captureDevice unlockForConfiguration];
        }
    }
}

/// Take the picture into the given path
- (void)takePictureAtPath:(NSString *)path {
    
    // Instanciate camera picture obj
    CameraPicture *cameraPicture = [[CameraPicture alloc] initWithPath:path
                                                           orientation:_deviceOrientation
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
