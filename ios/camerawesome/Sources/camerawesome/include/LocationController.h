//
//  LocationController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 07/09/2022.
//

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import "CamerawesomeCompileOptions.h"
#if CAMERAWESOME_USE_LOCATION
#import <CoreLocation/CoreLocation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnAuthorizationDeclined)(void);
typedef void(^OnAuthorizationGranted)(void);

#if CAMERAWESOME_USE_LOCATION

@interface LocationController : NSObject<CLLocationManagerDelegate>

@property (strong, nonatomic, nonnull) CLLocationManager *locationManager;
@property (nonatomic, copy) OnAuthorizationDeclined declinedBlock;
@property (nonatomic, copy) OnAuthorizationGranted grantedBlock;

- (instancetype)init;
- (void)requestWhenInUseAuthorizationOnGranted:(OnAuthorizationGranted)granted declined:(OnAuthorizationDeclined)declined;

@end

#else

// Stub interface when location support is compiled out. Keeps the public
// surface so call sites in SingleCameraPreview / MultiCameraPreview /
// CamerawesomePlugin still compile without further #ifdef churn.
@interface LocationController : NSObject

- (instancetype)init;
- (void)requestWhenInUseAuthorizationOnGranted:(OnAuthorizationGranted)granted declined:(OnAuthorizationDeclined)declined;

@end

#endif

NS_ASSUME_NONNULL_END
