package com.apparence.camerawesome;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.List;

import static android.Manifest.permission.CAMERA;
import static android.Manifest.permission.WRITE_EXTERNAL_STORAGE;

public class CameraPermissions {

    private static  final String[] permisions = new String[]{ CAMERA, WRITE_EXTERNAL_STORAGE };

    private static final int PERMISSIONS_MULTIPLE_REQUEST = 5;


    public static String[] checkPermissions(Activity activity) {
        if(activity == null) {
            throw new RuntimeException("NULL_ACTIVITY");
        }
        List<String> permissionsToAsk = new ArrayList<>();
        for(String permission : permisions) {
            if(ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED) {
                permissionsToAsk.add(permission);
            }
        }
        return permissionsToAsk.toArray(new String[0]);
    }

    public static void checkAndRequestPermissions(Activity activity) {
        String[] permissionsToAsk = checkPermissions(activity);
        if(permissionsToAsk.length > 0) {
            ActivityCompat.requestPermissions(
                    activity,
                    permissionsToAsk,
                    PERMISSIONS_MULTIPLE_REQUEST
            );
        }
    }
}
