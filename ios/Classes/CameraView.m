//
//  CameraView.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import "CameraView.h"
#import "CameraQualities.h"
#import "CameraPicture.h"

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

- (void)takePictureAtPath:(NSString *)path size:(CGSize)size andResult:(nonnull FlutterResult)result {
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
    
    // Get device orientation from device
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

    [_capturePhotoOutput capturePhotoWithSettings:settings
                                         delegate:[[CameraPicture alloc]
                                                   initWithPath:path
                                      orientation:deviceOrientation
                                      captureSize:size
                                           result:result]];
}

- (NSString *)selectAvailableCamera:(CameraSensor)sensor {
    NSArray<AVCaptureDevice *> *devices = [[NSArray alloc] init];
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                             discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                             mediaType:AVMediaTypeVideo
                                                             position:AVCaptureDevicePositionUnspecified];
        devices = discoverySession.devices;
    } else {
        // Fallback on earlier versions
    }
    
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
