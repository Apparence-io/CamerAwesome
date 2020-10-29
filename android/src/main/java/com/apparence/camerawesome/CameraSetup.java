package com.apparence.camerawesome;

import android.app.Activity;
import android.content.Context;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.os.Build;
import android.util.Size;
import android.view.OrientationEventListener;

import androidx.annotation.RequiresApi;

import com.apparence.camerawesome.models.CameraCharacteristicsModel;
import com.apparence.camerawesome.sensors.SensorOrientation;

import static android.view.OrientationEventListener.ORIENTATION_UNKNOWN;


@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
class CameraSetup {

    private Context context;

    private String mCameraId;

    private CameraManager mCameraManager;

    private Activity activity;

    private int currentOrientation = ORIENTATION_UNKNOWN;

    private int sensorOrientation;

    private OrientationEventListener orientationEventListener;

    private boolean facingFront;

    private CameraCharacteristicsModel characteristicsModel;

    private SensorOrientation sensorOrientationListener;

    CameraSetup(Context context, Activity activity, SensorOrientation sensorOrientationListener) {
        this.context = context;
        this.activity = activity;
        this.sensorOrientationListener = sensorOrientationListener;
    }

    void chooseCamera(CameraSensor sensor) throws CameraAccessException {
        mCameraManager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
        if(mCameraManager == null) {
            throw new CameraAccessException(CameraAccessException.CAMERA_ERROR, "cannot init CameraStateManager");
        }
        facingFront = sensor.equals(CameraSensor.FRONT);
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
            sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
            this.characteristicsModel = new CameraCharacteristicsModel.Builder()
                .withMaxZoom(characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM))
                .withAvailablePreviewZone(characteristics.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE))
                .withAutoFocus(characteristics.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES))
                .withFlash(characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE))
                .withAeCompensationRange(characteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE))
                .withAeCompensationStep(characteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_STEP))
                .build();
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
        final OrientationEventListener orientationEventListener = new OrientationEventListener(activity.getApplicationContext()) {
            @Override
            public void onOrientationChanged(int i) {
                if (i == ORIENTATION_UNKNOWN) {
                    return;
                }
                currentOrientation = (i + 45) / 90 * 90;
                if(currentOrientation == 360)
                    currentOrientation = 0;
                if(sensorOrientationListener != null)
                    sensorOrientationListener.notify(currentOrientation);
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

    /**
     * calculate orientation for exiv
     * @see CaptureRequest#JPEG_ORIENTATION
     * @return
     */
    public int getJpegOrientation() {
        final int sensorOrientationOffset =
                (currentOrientation == ORIENTATION_UNKNOWN)
                        ? 0
                        : (facingFront) ? -currentOrientation : currentOrientation;
        return (sensorOrientationOffset + sensorOrientation + 360) % 360;
    }

    /**
     * Used to wrap CameraCharacteristics in a simpler model
     * @return CameraCharacteristics
     */
    public CameraCharacteristicsModel getCharacteristicsModel() {
        return characteristicsModel;
    }

    // --------------------------------------------
    // GETTERS
    // --------------------------------------------

    public String getCameraId() {
        return mCameraId;
    }

    public int getCurrentOrientation() {
        return currentOrientation;
    }

}
