package com.apparence.camerawesome.utils

import android.hardware.camera2.CameraCharacteristics
import android.util.Size
import android.util.SizeF
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.CameraSelector.LENS_FACING_BACK
import com.apparence.camerawesome.cameraX.PigeonSensorPosition
import com.apparence.camerawesome.cameraX.PigeonSensorType
import kotlin.math.max
import kotlin.math.min

// 35mm is 135 film format, a standard in which focal lengths are usually measured
val Size35mm = Size(36, 24)

/**
 * Convert a given array of focal lengths to the corresponding TypeScript union type name.
 *
 * Possible values for single cameras:
 * * `"wide-angle-camera"`
 * * `"ultra-wide-angle-camera"`
 * * `"telephoto-camera"`
 *
 * Sources for the focal length categories:
 * * [Telephoto Lens (wikipedia)](https://en.wikipedia.org/wiki/Telephoto_lens)
 * * [Normal Lens (wikipedia)](https://en.wikipedia.org/wiki/Normal_lens)
 * * [Wide-Angle Lens (wikipedia)](https://en.wikipedia.org/wiki/Wide-angle_lens)
 * * [Ultra-Wide-Angle Lens (wikipedia)](https://en.wikipedia.org/wiki/Ultra_wide_angle_lens)
 */
@ExperimentalCamera2Interop
fun Camera2CameraInfo.getSensorType(): PigeonSensorType {
    val focalLengths =
        this.getCameraCharacteristic(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)!!
    val sensorSize =
        this.getCameraCharacteristic(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)!!

    // To get valid focal length standards we have to upscale to the 35mm measurement (film standard)
    val cropFactor = Size35mm.bigger / sensorSize.bigger


    val containsTelephoto =
        focalLengths.any { l -> (l * cropFactor) > 35 } // TODO: Telephoto lenses are > 85mm, but we don't have anything between that range..
    // val containsNormalLens = focalLengths.any { l -> (l * cropFactor) > 35 && (l * cropFactor) <= 55 }
    val containsWideAngle =
        focalLengths.any { l -> (l * cropFactor) >= 24 && (l * cropFactor) <= 35 }
    val containsUltraWideAngle = focalLengths.any { l -> (l * cropFactor) < 24 }

    if (containsTelephoto)
        return PigeonSensorType.TELEPHOTO
    if (containsWideAngle)
        return PigeonSensorType.WIDEANGLE
    if (containsUltraWideAngle)
        return PigeonSensorType.ULTRAWIDEANGLE
    return PigeonSensorType.UNKNOWN
}

@ExperimentalCamera2Interop
fun Camera2CameraInfo.getPigeonPosition(): PigeonSensorPosition {
    val facing = this.getCameraCharacteristic(CameraCharacteristics.LENS_FACING)!!
    return if (facing == LENS_FACING_BACK)
        PigeonSensorPosition.BACK
    else
        PigeonSensorPosition.FRONT
}


val Size.bigger: Int
    get() = max(this.width, this.height)
val Size.smaller: Int
    get() = min(this.width, this.height)

val SizeF.bigger: Float
    get() = max(this.width, this.height)
val SizeF.smaller: Float
    get() = min(this.width, this.height)