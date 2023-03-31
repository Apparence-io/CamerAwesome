package com.apparence.camerawesome.cameraX

import android.hardware.camera2.CameraCharacteristics
import android.os.Build
import android.util.Log
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.CameraSelector
import androidx.camera.lifecycle.ProcessCameraProvider

class CameraCapabilities {
    companion object {
        @androidx.annotation.OptIn(ExperimentalCamera2Interop::class)
        fun getCameraLevel(
            cameraSelector: CameraSelector,
            cameraProvider: ProcessCameraProvider
        ): Int {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                return cameraSelector.filter(cameraProvider.availableCameraInfos).firstOrNull()
                    ?.let { Camera2CameraInfo.from(it) }
                    ?.getCameraCharacteristic(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL)
                    ?: CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED
            }
            return CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY
        }
    }
}