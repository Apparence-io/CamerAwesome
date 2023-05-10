package com.apparence.camerawesome.cameraX

import android.app.Activity
import android.view.OrientationEventListener
import android.view.Surface
import com.apparence.camerawesome.sensors.SensorOrientation

class OrientationStreamListener(
    activity: Activity,
    private var listeners: List<SensorOrientation>
) {
    var currentOrientation: Int = 0
    val surfaceOrientation
        get() = when (currentOrientation) {
            in 225 until 315 -> {
                Surface.ROTATION_90
            }

            in 135 until 225 -> {
                Surface.ROTATION_180
            }

            in 45 until 135 -> {
                Surface.ROTATION_270
            }

            else -> {
                Surface.ROTATION_0
            }
        }

    private val orientationEventListener: OrientationEventListener

    init {
        orientationEventListener =
            object : OrientationEventListener(activity.applicationContext) {
                override fun onOrientationChanged(i: Int) {
                    if (i == ORIENTATION_UNKNOWN) {
                        return
                    }
                    currentOrientation = (i + 45) / 90 * 90
                    if (currentOrientation == 360) currentOrientation = 0
                    for (listener in listeners) {
                        listener.onOrientationChanged(currentOrientation)
                    }
                }
            }
        orientationEventListener.enable()
    }

    fun stop() {
        orientationEventListener.disable()
    }
}