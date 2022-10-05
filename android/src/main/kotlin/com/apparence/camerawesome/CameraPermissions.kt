package com.apparence.camerawesome

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

class CameraPermissions : EventChannel.StreamHandler, RequestPermissionsResultListener {
    private var permissionGranted = false
    private var events: EventSink? = null
    fun checkPermissions(activity: Activity?): Array<String> {
        if (activity == null) {
            throw RuntimeException("NULL_ACTIVITY")
        }
        val permissionsToAsk: MutableList<String> = ArrayList()
        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(
                    activity,
                    permission
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsToAsk.add(permission)
            }
        }
        permissionGranted = permissionsToAsk.size == 0
        return permissionsToAsk.toTypedArray()
    }

    fun checkAndRequestPermissions(activity: Activity?) {
        val permissionsToAsk = checkPermissions(activity)
        if (permissionsToAsk.size > 0) {
            Log.d(
                TAG,
                "_checkAndRequestPermissions: " + java.lang.String.join(",", *permissionsToAsk)
            )
            ActivityCompat.requestPermissions(
                activity!!,
                permissionsToAsk,
                PERMISSIONS_MULTIPLE_REQUEST
            )
        }
    }

    fun hasPermissionGranted(): Boolean {
        return permissionGranted
    }

    // ---------------------------------------------
    // EventChannel.StreamHandler
    // ---------------------------------------------
    override fun onListen(arguments: Any, events: EventSink) {
        this.events = events
    }

    override fun onCancel(arguments: Any) {
        if (events != null) {
            events!!.endOfStream()
            events = null
        }
    }

    // ---------------------------------------------
    // PluginRegistry.RequestPermissionsResultListener
    // ---------------------------------------------
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ): Boolean {
        permissionGranted = true
        for (i in permissions.indices) {
            if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                permissionGranted = false
                break
            }
        }
        if (events != null) {
            Log.d(
                TAG,
                "_onRequestPermissionsResult: granted " + java.lang.String.join(", ", *permissions)
            )
            events!!.success(permissionGranted)
        } else {
            Log.d(
                TAG,
                "_onRequestPermissionsResult: received permissions but the EventSink is closed"
            )
        }
        return permissionGranted
    }

    companion object {
        private val TAG = CameraPermissions::class.java.name
        private val permissions =
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.RECORD_AUDIO,
                Manifest.permission.ACCESS_FINE_LOCATION,
            )
        private const val PERMISSIONS_MULTIPLE_REQUEST = 5
    }
}