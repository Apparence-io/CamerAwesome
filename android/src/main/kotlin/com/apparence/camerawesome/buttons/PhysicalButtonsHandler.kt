package com.apparence.camerawesome.buttons

import android.os.Handler
import android.os.Looper
import android.os.Message
import io.flutter.plugin.common.EventChannel

class PhysicalButtonsHandler : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null

    fun buttonPressed(buttonId: Int) {
        when (buttonId) {
            VOLUME_DOWN -> {
                sink?.success("VOLUME_DOWN")
            }
            VOLUME_UP -> {
                sink?.success("VOLUME_UP")
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        if (sink != null) {
            sink?.endOfStream()
            sink = null
        }
    }

    companion object {
        const val BROADCAST_VOLUME_BUTTONS = "BROADCAST_VOLUME_BUTTONS"

        const val VOLUME_DOWN = 0
        const val VOLUME_UP = 1
    }
}

class PhysicalButtonMessageHandler(private val buttonsHandler: PhysicalButtonsHandler) :
    Handler(Looper.getMainLooper()) {

    override fun handleMessage(message: Message) {
        buttonsHandler.buttonPressed(message.arg1)
    }
}