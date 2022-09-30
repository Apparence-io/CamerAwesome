//
//  LocationController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 07/09/2022.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocationController : NSObject

@property (strong, nonatomic, nonnull) CLLocationManager *locationManager;

- (instancetype)init;
- (void)requestWhenInUseAuthorization;

@end

NS_ASSUME_NONNULL_END
