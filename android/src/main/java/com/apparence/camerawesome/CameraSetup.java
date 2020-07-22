package com.apparence.camerawesome;

import android.app.Activity;
import android.content.Context;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.os.Build;
import android.util.Log;
import android.util.Size;
import android.view.OrientationEventListener;

import androidx.annotation.RequiresApi;

import static android.view.OrientationEventListener.ORIENTATION_UNKNOWN;


@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
class CameraSetup {

    private Context context;

    private String mCameraId;

    private CameraManager mCameraManager;

    private Activity activity;

    private int currentOrientation = ORIENTATION_UNKNOWN;

    private OrientationEventListener orientationEventListener;

    CameraSetup(Context context, Activity activity) {
        this.context = context;
        this.activity = activity;
    }

    void chooseCamera(CameraSensor sensor) throws CameraAccessException {
        mCameraManager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
        if(mCameraManager == null) {
            throw new CameraAccessException(CameraAccessException.CAMERA_ERROR, "cannot init CameraStateManager");
        }
        for (String cameraId : mCameraManager.getCameraIdList()) {
            CameraCharacteristics characteristics = mCameraManager.getCameraCharacteristics(cameraId);
            Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
            if (facing == null
                    || (sensor == CameraSensor.FRONT && facing != CameraCharacteristics.LENS_FACING_FRONT)
                    || (sensor == CameraSensor.BACK && facing != CameraCharacteristics.LENS_FACING_BACK)) {
                continue;
            }
            StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
            if (map == null) {
                continue;
            }
            mCameraId = cameraId;
            return;
        }
        if(mCameraId == null) {
            throw new CameraAccessException(CameraAccessException.CAMERA_ERROR, "cannot find sensor");
        }
    }

    public void listenOrientation() {
        if(orientationEventListener != null) {
            return;
        }
        OrientationEventListener orientationEventListener = new OrientationEventListener(activity.getApplicationContext()) {
            @Override
            public void onOrientationChanged(int i) {
                if (i == ORIENTATION_UNKNOWN) {
                    return;
                }
                currentOrientation = (i + 45) / 90 * 90;
            }
        };
        orientationEventListener.enable();
    }

    Size[] getOutputSizes() throws CameraAccessException {
        if(mCameraManager == null) {
            throw new CameraAccessException(CameraAccessException.CAMERA_ERROR, "cannot init CameraStateManager");
        }
        CameraCharacteristics characteristics = mCameraManager.getCameraCharacteristics(mCameraId);
        StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
        return map.getOutputSizes(ImageFormat.JPEG);
    }

    public String getCameraId() {
        return mCameraId;
    }

    public int getCurrentOrientation() {
        return currentOrientation;
    }

}
