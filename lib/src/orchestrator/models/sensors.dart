enum Sensors {
  BACK,
  FRONT,
}

enum PreviewRatios {
  RATIO_16_9,
  RATIO_1_1,
  RATIO_4_3,
}

extension on PreviewRatios {
  PreviewRatios get defaultRatio => PreviewRatios.RATIO_4_3;
}
