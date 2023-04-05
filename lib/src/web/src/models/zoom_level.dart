import 'dart:html' as html;

import 'package:flutter/foundation.dart';

@immutable
class ZoomLevel {
  /// Creates a new instance of [ZoomLevel] with the given
  /// zoom level range of [minimum] to [maximum] configurable
  /// on the [videoTrack].
  const ZoomLevel({
    required this.minimum,
    required this.maximum,
    required this.videoTrack,
  });

  /// The zoom level constraint name.
  /// See: https://w3c.github.io/mediacapture-image/#dom-mediatracksupportedconstraints-zoom
  static const String constraintName = 'zoom';

  /// The minimum zoom level.
  final double minimum;

  /// The maximum zoom level.
  final double maximum;

  /// The video track capable of configuring the zoom level.
  final html.MediaStreamTrack videoTrack;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ZoomLevel &&
        other.minimum == minimum &&
        other.maximum == maximum &&
        other.videoTrack == videoTrack;
  }

  @override
  int get hashCode => Object.hash(minimum, maximum, videoTrack);
}
