//
//  PhysicalButtonsController.h
//  Pods
//
//  Created by Dimitri Dessus on 20/03/2023.
//

#import <Foundation/Foundation.h>
#import <JPSVolumeButtonHandler/JPSVolumeButtonHandler.h>
#import <Flutter/Flutter.h>
#import "PhysicalButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface PhysicalButtonController : NSObject {
  NSTimer *debounceTimer;
}

@property(nonatomic) FlutterEventSink physicalButtonEventSink;
@property(nonatomic) JPSVolumeButtonHandler *volumeButtonHandler;

- (instancetype)init;
- (void)stopListening;
- (void)startListening;
- (void)setPhysicalButtonEventSink:(FlutterEventSink)physicalButtonEventSink;

@end

NS_ASSUME_NONNULL_END
