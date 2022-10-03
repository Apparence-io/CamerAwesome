//
//  CameraFlash.h
//  camerawesome
//
//  Created by Dimitri Dessus on 27/07/2020.
//

#ifndef CameraFlash_h
#define CameraFlash_h

typedef enum {
  None,   // Flash is disabled
  On,     // Flash is always enabled when photo is taken
  Auto,   // Flash is enabled when user take a photo only if necessary
  Always, // Flash is enabled anytime, then trigger Auto mode when a photo is taken
} CameraFlashMode;

#endif /* CameraFlash_h */
