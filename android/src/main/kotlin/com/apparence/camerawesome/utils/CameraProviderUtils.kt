package com.apparence.camerawesome.utils

import android.annotation.SuppressLint
import androidx.camera.lifecycle.ProcessCameraProvider

@SuppressLint("RestrictedApi")
fun ProcessCameraProvider.isMultiCamSupported(): Boolean {
    val concurrentInfos = availableConcurrentCameraInfos
    var hasOnePair = false
    for (cameraInfos in concurrentInfos) {
        if (cameraInfos.size > 1) {
            hasOnePair = true
        }
    }
    return hasOnePair
}