package com.apparence.camerawesome;

import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CaptureRequest;
import android.os.Build;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraSession {

    private static final String TAG = CameraSession.class.getName();

    private static final String PREVIEW_SURFACE_KEY = "PREVIEW_SURFACE_KEY";

    private static final String PHOTO_SURFACE_KEY = "PHOTO_SURFACE_KEY";

    private CameraCaptureSession mCaptureSession;

    private List<OnCaptureSession> onCaptureSessionListenerList;

    private Map<String, Surface> surfaces = new HashMap();

    private CameraPictureStates state;

    private CameraDevice cameraDevice;


    void createCameraCaptureSession(final CameraDevice cameraDevice) throws CameraAccessException {
        this.cameraDevice = cameraDevice;
        cameraDevice.createCaptureSession(new ArrayList<>(surfaces.values()), new CameraCaptureSession.StateCallback() {
            @Override
            public void onConfigured(@NonNull CameraCaptureSession session) {
                mCaptureSession = session;
                if(onCaptureSessionListenerList != null) {
                    for (OnCaptureSession onCaptureSession : onCaptureSessionListenerList) {
                        onCaptureSession.onConfigured(session);
                    }
                }
            }

            @Override
            public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                if(mCaptureSession != null) {
                    mCaptureSession.close();
                }
                for (OnCaptureSession onCaptureSession : onCaptureSessionListenerList) {
                    onCaptureSession.onConfigureFailed();
                }
            }
        }, null);
    }

    public List<OnCaptureSession> getOnCaptureSessionListenerList() {
        return onCaptureSessionListenerList;
    }

    public void setOnCaptureSessionListenerList(List<OnCaptureSession> onCaptureSessionListenerList) {
        this.onCaptureSessionListenerList = onCaptureSessionListenerList;
    }

    public void addPreviewSurface(Surface surface) {
        this.surfaces.put(PREVIEW_SURFACE_KEY, surface);
        // todo if session is active recreate session
    }

    public void addPictureSurface(Surface surface) {
        this.surfaces.put(PHOTO_SURFACE_KEY, surface);
        // if session is active recreate session
        if(mCaptureSession != null) {
            try {
                mCaptureSession.abortCaptures();
                this.createCameraCaptureSession(cameraDevice);
            } catch (CameraAccessException e) {
                Log.e(TAG, "addPictureSurface: failed to recreate camera session", e);
            }
        }
    }

    public void clearSurface() {
        this.surfaces.clear();
    }

    public List<Surface> getSurfaces() {
        return new ArrayList<>(surfaces.values());
    }

    public CameraPictureStates getState() {
        return state;
    }

    public CameraDevice getCameraDevice() {
        return cameraDevice;
    }

    public void setState(CameraPictureStates state) {
        this.state = state;
        for (OnCaptureSession onCaptureSession : onCaptureSessionListenerList) {
            onCaptureSession.onStateChanged(this.state);
        }
    }

    public CameraCaptureSession getCaptureSession() {
        return mCaptureSession;
    }

    public void setCaptureSession(CameraCaptureSession mCaptureSession) {
        this.mCaptureSession = mCaptureSession;
    }

    /**
     * Used to signal that session is ready to all class using CameraSession
     */
    public interface OnCaptureSession {

        void onConfigured(@NonNull CameraCaptureSession session);

        void onConfigureFailed();

        void onStateChanged(CameraPictureStates state);
    }
}
