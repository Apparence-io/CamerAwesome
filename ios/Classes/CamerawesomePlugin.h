#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface CamerawesomePlugin : NSObject<FlutterPlugin, FlutterStreamHandler>
@end

@interface OrientationStreamHandler : NSObject <FlutterStreamHandler>
@end

@interface VideoRecordingStreamHandler : NSObject <FlutterStreamHandler>
@end

@interface ImageStreamHandler : NSObject <FlutterStreamHandler>
@end

NS_ASSUME_NONNULL_END
