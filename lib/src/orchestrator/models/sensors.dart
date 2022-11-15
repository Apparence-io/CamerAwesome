enum Sensors {
  BACK,
  FRONT,
}

enum CameraAspectRatios {
  RATIO_16_9,
  RATIO_4_3,
  RATIO_1_1, // only for iOS
}

extension on CameraAspectRatios {
  CameraAspectRatios get defaultRatio => CameraAspectRatios.RATIO_4_3;
}
