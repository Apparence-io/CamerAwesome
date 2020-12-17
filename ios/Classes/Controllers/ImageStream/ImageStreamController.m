//
//  ImageStreamController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import "ImageStreamController.h"

@implementation ImageStreamController

- (instancetype)initWithEventSink:(FlutterEventSink)imageStreamEventSink {
    self = [super init];
    _imageStreamEventSink = imageStreamEventSink;
    _streamImages = imageStreamEventSink != nil;
    return self;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    const Boolean isPlanar = CVPixelBufferIsPlanar(pixelBuffer);
    size_t planeCount;
    if (isPlanar) {
        planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
    } else {
        planeCount = 1;
    }
    
    FlutterStandardTypedData *data;
    for (int i = 0; i < planeCount; i++) {
        void *planeAddress;
        size_t bytesPerRow;
        size_t height;
        size_t width;
        
        if (isPlanar) {
            planeAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
            height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
            width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i);
        } else {
            planeAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
            bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
            height = CVPixelBufferGetHeight(pixelBuffer);
            width = CVPixelBufferGetWidth(pixelBuffer);
        }
        
        NSNumber *length = @(bytesPerRow * height);
        NSData *bytes = [NSData dataWithBytes:planeAddress length:length.unsignedIntegerValue];
        data = [FlutterStandardTypedData typedDataWithBytes:bytes];
    }
    
    // Only send bytes for now
    _imageStreamEventSink(data);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
}

@end
