package com.apparence.camerawesome;

import android.os.Build;

import androidx.annotation.RequiresApi;

import com.apparence.camerawesome.models.CameraCharacteristicsModel;

import java.util.List;

public class CameraSettingsManager {

    private CameraCharacteristicsModel mCameraCharacteristics;

    private CameraSettings cameraSettings;

    private List<CameraSettingsHandler> cameraSettingsHandlers;

    public CameraSettingsManager(CameraCharacteristicsModel mCameraCharacteristics,
                                 List<CameraSettingsHandler> cameraSettingsHandlers) {
        this.mCameraCharacteristics = mCameraCharacteristics;
        this.cameraSettingsHandlers = cameraSettingsHandlers;
        this.cameraSettings = new CameraSettings();
        cameraSettings.manualBrightness = 0;
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public void setManualBrightness(double value) {
        if(value > 1 || value < 0) {
            throw new IllegalArgumentException("Value for brightness compensation must be between 0 and 1");
        }
        int minCompensationRange = mCameraCharacteristics.getAeCompensationRange().getLower();
        int maxCompensationRange = mCameraCharacteristics.getAeCompensationRange().getUpper();
        double stepCompensation = mCameraCharacteristics.getAeCompensationRatio().doubleValue();
        if(minCompensationRange != 0 && maxCompensationRange != 0 ) {
            cameraSettings.manualBrightness = (int) (minCompensationRange + (maxCompensationRange - minCompensationRange) * (value));
            refreshConfiguration();
        }
    }

    private void refreshConfiguration() {
        if(cameraSettingsHandlers == null)
            return;
        for(CameraSettingsHandler handler: cameraSettingsHandlers) {
            handler.refreshConfiguration(cameraSettings);
        }
    }

    public class CameraSettings {
        int manualBrightness;
    }

    public interface CameraSettingsHandler {

        void refreshConfiguration(CameraSettings settings);
    }
}
