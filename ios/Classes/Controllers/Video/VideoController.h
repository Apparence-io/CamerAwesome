//
//  VideoController.h
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Pigeon.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^OnAudioSetup)(void);
typedef void(^OnVideoWriterSetup)(void);

@interface VideoController : NSObject

@property(readonly, nonatomic) bool isRecording;
@property(readonly, nonatomic) bool isPaused;
@property(readonly, nonatomic) bool isAudioEnabled;
@property(readonly, nonatomic) bool isAudioSetup;
@property NSInteger orientation;
@property(readonly, nonatomic) AVAssetWriter *videoWriter;
@property(readonly, nonatomic) AVAssetWriterInput *videoWriterInput;
@property(readonly, nonatomic) AVAssetWriterInput *audioWriterInput;
@property(readonly, nonatomic) AVAssetWriterInputPixelBufferAdaptor *videoAdaptor;
@property(readonly, nonatomic) bool videoIsDisconnected;
@property(readonly, nonatomic) bool audioIsDisconnected;
@property(readonly, nonatomic) CGSize previewSize;
@property(assign, nonatomic) CMTime lastVideoSampleTime;
@property(assign, nonatomic) CMTime lastAudioSampleTime;
@property(assign, nonatomic) CMTime videoTimeOffset;
@property(assign, nonatomic) CMTime audioTimeOffset;

- (instancetype)init;
- (void)recordVideoAtPath:(NSString *)path orientation:(NSInteger)orientation audioSetupCallback:(OnAudioSetup)audioSetupCallback videoWriterCallback:(OnVideoWriterSetup)videoWriterCallback options:(VideoOptions *)options completion:(nonnull void (^)(FlutterError * _Nullable))completion;
- (void)stopRecordingVideo:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion;
- (void)pauseVideoRecording;
- (void)resumeVideoRecording;
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection captureVideoOutput:(AVCaptureVideoDataOutput *)captureVideoOutput;
- (void)setIsAudioEnabled:(bool)isAudioEnabled;
- (void)setIsAudioSetup:(bool)isAudioSetup;
- (void)setVideoIsDisconnected:(bool)videoIsDisconnected;
- (void)setAudioIsDisconnected:(bool)audioIsDisconnected;
- (void)setPreviewSize:(CGSize)previewSize;

@end

NS_ASSUME_NONNULL_END
