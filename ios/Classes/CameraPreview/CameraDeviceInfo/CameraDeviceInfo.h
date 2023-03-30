//
//  CameraDeviceInfo.h
//  camerawesome
//
//  Created by Dimitri Dessus on 29/03/2023.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraDeviceInfo : NSObject

@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureConnection *captureConnection;

@end

NS_ASSUME_NONNULL_END
