//
//  PhysicalButtonsController.m
//  Pods
//
//  Created by Dimitri Dessus on 20/03/2023.
//

#import "PhysicalButtonController.h"

@implementation PhysicalButtonController

- (instancetype)init {
  self = [super init];
  self.volumeButtonHandler = [JPSVolumeButtonHandler volumeButtonHandlerWithUpBlock:^{
    [self tryToSendPhysicalEvent:volume_up];
  } downBlock:^{
    [self tryToSendPhysicalEvent:volume_down];
  }];
  return self;
}

- (void)tryToSendPhysicalEvent:(PhysicalButton)physicalButton {
  if (debounceTimer != nil) {
    [debounceTimer invalidate];
    debounceTimer = nil;
  }
  
  debounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                     repeats:NO
                                                       block:^(NSTimer *timer) {
    if (self->_physicalButtonEventSink != nil) {
      NSString *physicalButtonString;
      switch (physicalButton) {
        case volume_up:
          physicalButtonString = @"VOLUME_UP";
          break;
        case volume_down:
          physicalButtonString = @"VOLUME_DOWN";
          break;
        default:
          return;
      }
      
      self->_physicalButtonEventSink(physicalButtonString);
    }
  }];
}

- (void)startListening {
  [self.volumeButtonHandler startHandler:YES];
}

- (void)stopListening {
  if (self.volumeButtonHandler != nil) {
    [self.volumeButtonHandler stopHandler];
  }
}

- (void)setPhysicalButtonEventSink:(FlutterEventSink)physicalButtonEventSink {
  _physicalButtonEventSink = physicalButtonEventSink;
}

@end
