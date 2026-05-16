//
//  LocationController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 07/09/2022.
//

#import "LocationController.h"

#if CAMERAWESOME_USE_LOCATION

@implementation LocationController

- (instancetype)init {
  if (self = [super init]) {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  }

  return self;
}

- (void)requestWhenInUseAuthorizationOnGranted:(OnAuthorizationGranted)granted declined:(OnAuthorizationDeclined)declined {
  _grantedBlock = granted;
  _declinedBlock = declined;

  if (self.locationManager.authorizationStatus ==  kCLAuthorizationStatusNotDetermined) {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
      [self.locationManager requestWhenInUseAuthorization];
    }
  } else if (self.locationManager.authorizationStatus ==  kCLAuthorizationStatusAuthorizedAlways || self.locationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
    _grantedBlock();
  } else {
    _declinedBlock();
  }
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
  if (manager.authorizationStatus ==  kCLAuthorizationStatusAuthorizedAlways || manager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
    if (_grantedBlock != nil) {
      _grantedBlock();
    }

  } else {
    if (_declinedBlock != nil) {
      _declinedBlock();
    }

  }
}

@end

#else

// Stub implementation when CAMERAWESOME_DISABLE_LOCATION=1.
// Always declines any authorization request so callers fall back to
// the "no GPS in EXIF" path without ever touching CoreLocation.
@implementation LocationController

- (instancetype)init {
  return [super init];
}

- (void)requestWhenInUseAuthorizationOnGranted:(OnAuthorizationGranted)granted declined:(OnAuthorizationDeclined)declined {
  if (declined != nil) {
    declined();
  }
}

@end

#endif
