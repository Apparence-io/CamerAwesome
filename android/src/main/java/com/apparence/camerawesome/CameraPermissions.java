package com.apparence.camerawesome;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.StringJoiner;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry;

import static android.Manifest.permission.CAMERA;
import static android.Manifest.permission.WRITE_EXTERNAL_STORAGE;

public class CameraPermissions implements EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {

    private static final String TAG = CameraPermissions.class.getName();

    private static final List<String> permissions = new ArrayList<String>();

    private static final int PERMISSIONS_MULTIPLE_REQUEST = 5;

    private boolean permissionGranted = false;

    private EventChannel.EventSink events;



    public String[] checkPermissions(Activity activity, boolean ignoreExternalStorage) {
        if(activity == null) {
            throw new RuntimeException("NULL_ACTIVITY");
        }
        if (permissions.isEmpty()) {
            permissions.add(CAMERA);
            if (!ignoreExternalStorage) {
                permissions.add(WRITE_EXTERNAL_STORAGE);
            }
        }
        List<String> permissionsToAsk = new ArrayList<>();
        for(String permission : permissions) {
            if(ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToAsk.add(permission);
            }
        }
        this.permissionGranted = permissionsToAsk.size() == 0;
        return permissionsToAsk.toArray(new String[0]);
    }

    public void checkAndRequestPermissions(Activity activity, boolean ignoreExternalStorage) {
        String[] permissionsToAsk = checkPermissions(activity, ignoreExternalStorage);
        if(permissionsToAsk.length > 0) {
            Log.d(TAG, "_checkAndRequestPermissions: " + String.join(",", permissionsToAsk));
            ActivityCompat.requestPermissions(
                    activity,
                    permissionsToAsk,
                    PERMISSIONS_MULTIPLE_REQUEST
            );
        }
    }

    public boolean hasPermissionGranted() {
        return permissionGranted;
    }

    // ---------------------------------------------
    // EventChannel.StreamHandler
    // ---------------------------------------------

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.events = events;
    }

    @Override
    public void onCancel(Object arguments) {
        if(this.events != null) {
            this.events.endOfStream();
            this.events = null;
        }
    }

    // ---------------------------------------------
    // PluginRegistry.RequestPermissionsResultListener
    // ---------------------------------------------

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        permissionGranted = true;
        for(int i=0; i < permissions.length; i++) {
            if(grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                permissionGranted = false;
                break;
            }
        }
        if(this.events != null) {
            Log.d(TAG, "_onRequestPermissionsResult: granted " + String.join(", ", permissions));
            this.events.success(permissionGranted);
        } else {
            Log.d(TAG, "_onRequestPermissionsResult: received permissions but the EventSink is closed");
        }

        return permissionGranted;
    }
}
