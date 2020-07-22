#import "CamerawesomePlugin.h"
#if __has_include(<camerawesome/camerawesome-Swift.h>)
#import <camerawesome/camerawesome-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "camerawesome-Swift.h"
#endif

@implementation CamerawesomePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCamerawesomePlugin registerWithRegistrar:registrar];
}
@end
