//
//  CamerawesomeCompileOptions.h
//  camerawesome
//
//  Compile-time feature gates so consumers can strip optional iOS APIs
//  (microphone, location) from the binary. This eliminates the App Store
//  Connect ITMS-90683 warning for apps that do not record video audio or
//  embed GPS in EXIF.
//
//  Activate by setting the matching preprocessor flag from a consumer
//  Podfile (post_install hook), e.g.:
//
//    post_install do |installer|
//      installer.pods_project.targets.each do |target|
//        next unless target.name == 'camerawesome'
//        target.build_configurations.each do |config|
//          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
//          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'CAMERAWESOME_DISABLE_MICROPHONE=1'
//          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'CAMERAWESOME_DISABLE_LOCATION=1'
//        end
//      end
//    end
//
//  Default: both features enabled (backwards compatible).
//

#ifndef CamerawesomeCompileOptions_h
#define CamerawesomeCompileOptions_h

#ifndef CAMERAWESOME_USE_MICROPHONE
  #if defined(CAMERAWESOME_DISABLE_MICROPHONE) && CAMERAWESOME_DISABLE_MICROPHONE
    #define CAMERAWESOME_USE_MICROPHONE 0
  #else
    #define CAMERAWESOME_USE_MICROPHONE 1
  #endif
#endif

#ifndef CAMERAWESOME_USE_LOCATION
  #if defined(CAMERAWESOME_DISABLE_LOCATION) && CAMERAWESOME_DISABLE_LOCATION
    #define CAMERAWESOME_USE_LOCATION 0
  #else
    #define CAMERAWESOME_USE_LOCATION 1
  #endif
#endif

#endif /* CamerawesomeCompileOptions_h */
