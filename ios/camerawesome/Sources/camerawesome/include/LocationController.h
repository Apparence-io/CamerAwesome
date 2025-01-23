//
//  LocationController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 07/09/2022.
//

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnAuthorizationDeclined)(void);
typedef void(^OnAuthorizationGranted)(void);

@interface LocationController : NSObject<CLLocationManagerDelegate>

@property (strong, nonatomic, nonnull) CLLocationManager *locationManager;
@property (nonatomic, copy) OnAuthorizationDeclined declinedBlock;
@property (nonatomic, copy) OnAuthorizationGranted grantedBlock;

- (instancetype)init;
- (void)requestWhenInUseAuthorizationOnGranted:(OnAuthorizationGranted)granted declined:(OnAuthorizationDeclined)declined;

@end

NS_ASSUME_NONNULL_END
