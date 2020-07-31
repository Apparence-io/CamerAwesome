#import "CamerawesomePlugin.h"
#import "CameraView.h"

@interface CamerawesomePlugin ()

@property(readonly, nonatomic) NSObject<FlutterTextureRegistry> *registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@property FlutterEventSink eventSink;
@property int64_t textureId;
@property CameraView *camera;

- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry> *)registry messenger:(NSObject<FlutterBinaryMessenger> *)messenger;

@end

@implementation CamerawesomePlugin
- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry> *)registry
                       messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = registry;
    _messenger = messenger;

    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    CamerawesomePlugin *instance = [[CamerawesomePlugin alloc] initWithRegistry:[registrar textures] messenger:[registrar messenger]];
    
    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"camerawesome/orientation"
    binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
    
    // TODO: Change to "camerawesome/methods"
    FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:@"camerawesome" binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        [self _handleSetup:call result:result];
    } else if ([@"checkPermissions" isEqualToString:call.method]) {
        [self _handleCheckPermissions:call result:result];
    } else if ([@"requestPermissions" isEqualToString:call.method]) {
        // Not possible on iOS
        result(FlutterMethodNotImplemented);
        return;
    } else if ([@"start" isEqualToString:call.method]) {
        [self _handleStart:call result:result];
    } else if ([@"stop" isEqualToString:call.method]) {
        [self _handleStop:call result:result];
    } else if ([@"availableSizes" isEqualToString:call.method]) {
        [self _handleSizes:call result:result];
    } else if ([@"previewTexture" isEqualToString:call.method]) {
        [self _handleGetTextures:call result:result];
    } else if ([@"setPreviewSize" isEqualToString:call.method]) {
        [self _handlePreviewSize:call result:result];
    } else if ([@"getEffectivPreviewSize" isEqualToString:call.method]) {
        [self _handleGetEffectivPreviewSize:call result:result];
    } else if ([@"setPhotoSize" isEqualToString:call.method]) {
        [self _handlePhotoSize:call result:result];
    } else if ([@"takePhoto" isEqualToString:call.method]) {
        [self _handleTakePhoto:call result:result];
    } else if ([@"handleAutoFocus" isEqualToString:call.method]) {
        [self _handleAutoFocus:call result:result];
    } else if ([@"setFlashMode" isEqualToString:call.method]) {
        [self _handleFlashMode:call result:result];
    } else if ([@"flipCamera" isEqualToString:call.method]) {
        [self _handleFlipCamera:call result:result];
    } else if ([@"setZoom" isEqualToString:call.method]) {
        [self _handleSetZoom:call result:result];
    } else if ([@"getMaxZoom" isEqualToString:call.method]) {
        [self _handleGetMaxZoom:call result:result];
    } else if ([@"dispose" isEqualToString:call.method]) {
        [self _handleDispose:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
        return;
    }
}

- (void)_handleGetEffectivPreviewSize:(FlutterMethodCall*)call result:(FlutterResult)result {
    CGSize previewSize = [_camera getEffectivPreviewSize];
    result(@{
        @"width": [NSNumber numberWithInt:previewSize.width],
        @"height": [NSNumber numberWithInt:previewSize.height],
    });
}

- (void)_handleSetZoom:(FlutterMethodCall*)call result:(FlutterResult)result {
    float value = [call.arguments[@"zoom"] floatValue];
    
    [_camera setZoom:value];
}

- (NSInteger)_handleGetMaxZoom:(FlutterMethodCall*)call result:(FlutterResult)result {
    return [_camera getMaxZoom];
}

- (void)_handleDispose:(FlutterMethodCall*)call result:(FlutterResult)result {
    [_camera dispose];
}

- (void)_handleTakePhoto:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *path = call.arguments[@"path"];
    
    if (path == nil || path.length <= 0) {
        result([FlutterError errorWithCode:@"PATH_NOT_SET" message:@"a file path must be set" details:nil]);
        return;
    }
    
    [_camera setResult:result];
    [_camera takePictureAtPath:path];
}

- (void)_handleFlipCamera:(FlutterMethodCall*)call result:(FlutterResult)result {
    [_camera flipCamera];
}

- (void)_handleAutoFocus:(FlutterMethodCall*)call result:(FlutterResult)result {
    [_camera setResult:result];
    [_camera instantFocus];
}

- (void)_handleCheckPermissions:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(@([CameraPermissions checkPermissions]));
}

- (void)_handleSizes:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(kCameraQualities);
}

- (void)_handlePreviewSize:(FlutterMethodCall*)call result:(FlutterResult)result {
    float width = [call.arguments[@"width"] floatValue];
    float height = [call.arguments[@"height"] floatValue];
    
    if (width <= 0 || height <= 0) {
        result([FlutterError errorWithCode:@"NO_SIZE_SET" message:@"width and height must be set" details:nil]);
        return;
    }
    
    if (self.camera == nil) {
        result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
        return;
    }
    
    [self.camera setPreviewSize:CGSizeMake(width, height)];
    
    result(nil);
}

- (void)_handlePhotoSize:(FlutterMethodCall*)call result:(FlutterResult)result {
    float width = [call.arguments[@"width"] floatValue];
    float height = [call.arguments[@"height"] floatValue];
    
    if (width <= 0 || height <= 0) {
        result([FlutterError errorWithCode:@"NO_SIZE_SET" message:@"width and height must be set" details:nil]);
        return;
    }
    
    if (self.camera == nil) {
        result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
        return;
    }
    
    // TODO: Set size inside camera
    
    result(nil);
}

- (void)_handleStart:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (self.camera == nil) {
        result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
        return;
    }
    
    [_camera start];
    
    result(@(YES));
}

- (void)_handleStop:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (self.camera == nil) {
        result([FlutterError errorWithCode:@"CAMERA_MUST_BE_INIT" message:@"init must be call before start" details:nil]);
        return;
    }
    
    [_camera stop];
    
    result(@(YES));
}

- (void)_handleSetup:(FlutterMethodCall*)call result:(FlutterResult)result  {
    NSString *sensorName = call.arguments[@"sensor"];
    
    if (![CameraPermissions checkPermissions]) {
        result([FlutterError errorWithCode:@"MISSING_PERMISSION" message:@"you got to accept all permissions" details:nil]);
        return;
    }
    
    if (sensorName == nil || sensorName.length <= 0) {
        result([FlutterError errorWithCode:@"SENSOR_ERROR" message:@"a sensor FRONT or BACK must be provided" details:nil]);
        return;
    }

    CameraSensor sensor = ([sensorName isEqualToString:@"FRONT"]) ? Front : Back;
    self.camera = [[CameraView alloc] initWithCameraSensor:sensor
                                                    result:result
                                                 messenger:_messenger
                                                     event:_eventSink];
    [self->_registry textureFrameAvailable:_textureId];
    
    __weak typeof(self) weakSelf = self;
    self.camera.onFrameAvailable = ^{
        [weakSelf.registry textureFrameAvailable:weakSelf.textureId];
    };
    
    // Assign texture id
    _textureId = [_registry registerTexture:self.camera];
    result(@(YES));
}

- (void)_handleFlashMode:(FlutterMethodCall*)call result:(FlutterResult)result  {
    NSString *flashMode = call.arguments[@"mode"];
    
    if (flashMode == nil || flashMode.length <= 0) {
        result([FlutterError errorWithCode:@"FLASH_MODE_ERROR" message:@"a flash mode NONE, AUTO, ALWAYS must be provided" details:nil]);
        return;
    }

    CameraFlashMode flash;
    if ([flashMode isEqualToString:@"NONE"]) {
        flash = None;
    } else if ([flashMode isEqualToString:@"AUTO"]) {
        flash = Auto;
    } else if ([flashMode isEqualToString:@"ALWAYS"]) {
        flash = Always;
    } else {
        flash = None;
    }
    
    [_camera setResult:result];
    [_camera setFlashMode:flash];
    result(@(YES));
}

- (void)_handleGetTextures:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(@(_textureId));
}

@end
