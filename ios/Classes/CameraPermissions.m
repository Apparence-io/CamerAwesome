//
//  CameraPermissions.m
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#import <AVFoundation/AVFoundation.h>
#import "CameraPermissions.h"

@implementation CameraPermissions

+ (BOOL)checkPermissions {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    __block BOOL permissionsGranted;
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
         [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
           permissionsGranted = granted;
           dispatch_semaphore_signal(sem);
         }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    } else {
      permissionsGranted = (authStatus == AVAuthorizationStatusAuthorized);
    }
    
    return permissionsGranted;
}

@end
