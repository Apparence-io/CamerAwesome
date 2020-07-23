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
import java.util.List;


@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraSession {

    private static final String TAG = CameraSession.class.getName();

    private CameraCaptureSession mCaptureSession;

    private List<OnCaptureSession> onCaptureSessionListenerList;

    private List<Surface> surfaces = new ArrayList<>();

    void createCameraCaptureSession(final CameraDevice cameraDevice) throws CameraAccessException {
        cameraDevice.createCaptureSession(surfaces, new CameraCaptureSession.StateCallback() {
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

    public void addSurface(Surface surface) {
        this.surfaces.add(surface);
        // todo if session is active recreate session
    }

    public void clearSurface(Surface surface) {
        this.surfaces.remove(surface);
        // todo if session is active recreate session
    }


    /**
     * Used to signal that session is ready to all class using CameraSession
     */
    public interface OnCaptureSession {

        void onConfigured(@NonNull CameraCaptureSession session);

        void onConfigureFailed();
    }
}
