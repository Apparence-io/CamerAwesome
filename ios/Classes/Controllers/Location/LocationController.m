//
//  LocationController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 07/09/2022.
//

#import "LocationController.h"

@implementation LocationController

- (instancetype)init {
  self = [super init];
  
  if (!self) {
    return nil;
  }
  
  self.locationManager = [[CLLocationManager alloc] init];
  
  self.locationManager.distanceFilter = kCLDistanceFilterNone;
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  
  return self;
}

- (void)requestWhenInUseAuthorization {
  if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
    [self.locationManager requestWhenInUseAuthorization];
  }
}

@end
