//
//  CameraPicture.m
//  Pods
//
//  Created by Dimitri Dessus on 02/12/2020.
//

// This is all related stuff to taking picture

/// Take the picture into the given path
- (void)takePictureAtPath:(NSString *)path {
    
    // Instanciate camera picture obj
    CameraPictureController *cameraPicture = [[CameraPictureController alloc] initWithPath:path
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
