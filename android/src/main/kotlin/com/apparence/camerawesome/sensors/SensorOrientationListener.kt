package com.apparence.camerawesome.sensors

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class SensorOrientationListener : EventChannel.StreamHandler, SensorOrientation {
    var events: EventSink? = null
    override fun onListen(arguments: Any, events: EventSink) {
        this.events = events
    }

    override fun onCancel(arguments: Any?) {
        events?.endOfStream()
        events = null
    }

    override fun onOrientationChanged(orientation: Int) {
        if (events == null) {
            return
        }
        when (orientation) {
            0 -> events!!.success("PORTRAIT_UP")
            90 -> events!!.success("LANDSCAPE_LEFT")
            180 -> events!!.success("PORTRAIT_DOWN")
            270 -> events!!.success("LANDSCAPE_RIGHT")
        }
    }
}