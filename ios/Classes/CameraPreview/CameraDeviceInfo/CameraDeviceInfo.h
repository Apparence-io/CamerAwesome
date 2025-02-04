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

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *captureConnection;
@property (nonatomic, strong) AVCapturePhotoOutput *capturePhotoOutput;

@end

NS_ASSUME_NONNULL_END
