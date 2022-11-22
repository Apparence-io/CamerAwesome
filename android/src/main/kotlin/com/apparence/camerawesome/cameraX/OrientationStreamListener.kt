package com.apparence.camerawesome.cameraX

import android.app.Activity
import android.view.OrientationEventListener
import com.apparence.camerawesome.sensors.SensorOrientation

class OrientationStreamListener(
    activity: Activity,
    private var sensorOrientationListener: SensorOrientation
) {
    var currentOrientation: Int = 0

    init {
        val orientationEventListener: OrientationEventListener =
            object : OrientationEventListener(activity.applicationContext) {
                override fun onOrientationChanged(i: Int) {
                    if (i == ORIENTATION_UNKNOWN) {
                        return
                    }
                    currentOrientation = (i + 45) / 90 * 90
                    if (currentOrientation == 360) currentOrientation = 0
                    sensorOrientationListener.notify(
                        currentOrientation
                    )
                }
            }
        orientationEventListener.enable()
    }
}