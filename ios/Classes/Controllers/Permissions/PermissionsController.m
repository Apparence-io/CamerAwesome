//
//  PermissionsController.m
//  _NIODataStructures
//
//  Created by Dimitri Dessus on 27/12/2022.
//

#import "PermissionsController.h"

@implementation CameraPermissionsController

+ (BOOL)checkPermission {
  AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  
  return (authStatus == AVAuthorizationStatusAuthorized);
}

+ (BOOL)checkAndRequestPermission {
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

@implementation MicrophonePermissionsController

+ (BOOL)checkPermission {
  AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
  
  return (permissionStatus == AVAudioSessionRecordPermissionGranted);
}

+ (BOOL)checkAndRequestPermission {
  AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
  
  __block BOOL permissionsGranted;
  if (permissionStatus == AVAudioSessionRecordPermissionUndetermined) {
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
      permissionsGranted = granted;
      dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  } else {
    permissionsGranted = (permissionStatus == AVAudioSessionRecordPermissionGranted);
  }
  
  return permissionsGranted;
}

@end
