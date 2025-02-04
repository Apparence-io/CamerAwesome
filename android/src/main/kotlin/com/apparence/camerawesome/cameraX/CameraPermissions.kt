package com.apparence.camerawesome.cameraX

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.apparence.camerawesome.exceptions.PermissionNotDeclaredException
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.*
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class CameraPermissions : EventChannel.StreamHandler, RequestPermissionsResultListener {
    private var permissionGranted = false
    private var events: EventSink? = null
    private var callbacks: MutableList<PermissionRequest> = mutableListOf()

    // ---------------------------------------------
    // EventChannel.StreamHandler
    // ---------------------------------------------
    override fun onListen(arguments: Any?, events: EventSink?) {
        this.events = events
    }

    override fun onCancel(arguments: Any?) {
        if (events != null) {
            events!!.endOfStream()
            events = null
        }
    }

    // ---------------------------------------------
    // PluginRegistry.RequestPermissionsResultListener
    // ---------------------------------------------
    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ): Boolean {
        val grantedPermissions = mutableListOf<String>()
        val deniedPermissions = mutableListOf<String>()
        permissionGranted = true
        for (i in permissions.indices) {
            if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
                grantedPermissions.add(permissions[i])
            } else {
                permissionGranted = false
                deniedPermissions.add(permissions[i])
            }
        }
        val toRemove = mutableListOf<PermissionRequest>()
        for (c in callbacks) {
            if (c.permissionsAsked.containsAll(permissions.toList()) && permissions.toList()
                    .containsAll(c.permissionsAsked)
            ) {
                c.callback(grantedPermissions, deniedPermissions)
                toRemove.add(c)
            }
        }
        callbacks.removeAll(toRemove)

        if (events != null) {
            Log.d(
                TAG,
                "_onRequestPermissionsResult: granted " + java.lang.String.join(", ", *permissions)
            )
            events!!.success(permissionGranted)
        } else {
            Log.d(
                TAG, "_onRequestPermissionsResult: received permissions but the EventSink is closed"
            )
        }
        return permissionGranted
    }

    fun requestBasePermissions(
        activity: Activity,
        saveGps: Boolean,
        recordAudio: Boolean,
        callback: (granted: List<String>) -> Unit
    ) {
        val declared = declaredCameraPermissions(activity)
        // Remove declared permissions not required now
        if (!saveGps) {
            declared.remove(Manifest.permission.ACCESS_FINE_LOCATION)
            declared.remove(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        if (!recordAudio) {
            declared.remove(Manifest.permission.RECORD_AUDIO)
        }
        // Throw exception if permission not declared but required here
        if (saveGps && !declared.contains(Manifest.permission.ACCESS_FINE_LOCATION)) {
            throw PermissionNotDeclaredException(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        if (saveGps && !declared.contains(Manifest.permission.ACCESS_COARSE_LOCATION)) {
            throw PermissionNotDeclaredException(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        if (recordAudio && !declared.contains(Manifest.permission.RECORD_AUDIO)) {
            throw PermissionNotDeclaredException(Manifest.permission.RECORD_AUDIO)
        }

        // Check if some of the permissions have already been given
        val permissionsToAsk: MutableList<String> = ArrayList()
        val permissionsGranted: MutableList<String> = ArrayList()
        for (permission in declared) {
            if (ContextCompat.checkSelfPermission(
                    activity, permission
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsToAsk.add(permission)
            } else {
                permissionsGranted.add(permission)
            }
        }
        permissionGranted = permissionsToAsk.size == 0
        if (permissionsToAsk.isEmpty()) {
            callback(permissionsGranted)
        } else {
            // Request the not granted permissions
            CoroutineScope(Dispatchers.IO).launch {
                requestPermissions(activity, permissionsToAsk, PERMISSIONS_MULTIPLE_REQUEST) {
                    callback(permissionsGranted.apply { addAll(it) })
                }
            }
        }
    }


    /**
     * Returns the list of declared camera related permissions
     */
    private fun declaredCameraPermissions(context: Context): MutableList<String> {
        val packageInfo = context.packageManager.getPackageInfo(
            context.packageName, PackageManager.GET_PERMISSIONS
        )
        val permissions = packageInfo.requestedPermissions
        val declaredPermissions = mutableListOf<String>()
        if (permissions.isNullOrEmpty()) return declaredPermissions

        for (perm in permissions) {
            if (allPermissions.contains(perm)) {
                declaredPermissions.add(perm)
            }
        }
        return declaredPermissions
    }

    fun hasPermission(activity: Activity, permissions: List<String>): Boolean {
        var granted = true
        for (p in permissions) {
            if (ContextCompat.checkSelfPermission(
                    activity, p
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                granted = false
                break
            }
        }
        return granted
    }

    suspend fun requestPermissions(
        activity: Activity,
        permissions: List<String>,
        requestCode: Int,
        callback: (denied: List<String>) -> Unit
    ) {
        val result: List<String> = suspendCoroutine { continuation: Continuation<List<String>> ->
            ActivityCompat.requestPermissions(
                activity, permissions.toTypedArray(), requestCode
            )
            callbacks.add(
                PermissionRequest(UUID.randomUUID().toString(),
                    permissions,
                    callback = { granted, _ ->
                        continuation.resume(granted)
                    })
            )
        }
        callback(result)
    }

    companion object {
        private val TAG = CameraPermissions::class.java.name
        const val PERMISSIONS_MULTIPLE_REQUEST = 550
        const val PERMISSION_GEOLOC = 560
        const val PERMISSION_RECORD_AUDIO = 570

        val allPermissions = listOf(
            Manifest.permission.CAMERA,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
    }
}

data class PermissionRequest(
    var id: String,
    val permissionsAsked: List<String>,
    val callback: (permissionsGranted: List<String>, permissionsDenied: List<String>) -> Unit
) {}