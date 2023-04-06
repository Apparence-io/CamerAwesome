import 'dart:html';

import 'package:camerawesome/src/web/src/models/camera_direction.dart';
import 'package:flutter/material.dart';

@immutable
class CameraMetadata {
  /// The name of the camera device.
  final String name;

  /// The direction the camera is facing.
  final CameraDirection cameraDirection;

  /// Uniquely identifies the camera device.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaDeviceInfo/deviceId
  final String deviceId;

  /// Describes the direction the camera is facing towards.
  /// May be `user`, `environment`, `left`, `right`
  /// or null if the facing mode is not available.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackSettings/facingMode
  final String? facingMode;
  const CameraMetadata({
    required this.name,
    required this.cameraDirection,
    required this.deviceId,
    this.facingMode,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CameraMetadata &&
        other.name == name &&
        other.cameraDirection == cameraDirection &&
        other.deviceId == deviceId &&
        other.facingMode == facingMode;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        cameraDirection.hashCode ^
        deviceId.hashCode ^
        facingMode.hashCode;
  }

  factory CameraMetadata.create(
    final MediaDeviceInfo deviceInfo,
    final String? facingMode,
  ) {
    // Get the lens direction based on the facing mode.
    // Fallback to the external lens direction
    // if the facing mode is not available.
    final CameraDirection cameraDirection = facingMode != null
        ? CameraDirection.fromFacingMode(facingMode)
        : CameraDirection.external;

    return CameraMetadata(
      name: deviceInfo.label ?? '',
      cameraDirection: cameraDirection,
      deviceId: deviceInfo.deviceId!,
      facingMode: facingMode,
    );
  }
}
