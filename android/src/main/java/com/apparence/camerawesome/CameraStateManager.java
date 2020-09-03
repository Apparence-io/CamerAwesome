package com.apparence.camerawesome;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;

import com.apparence.camerawesome.exceptions.CameraManagerException;
import com.apparence.camerawesome.exceptions.CameraPreviewException;
import com.apparence.camerawesome.models.CameraCharacteristicsModel;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import io.flutter.view.TextureRegistry;

import static com.apparence.camerawesome.exceptions.CameraManagerException.Codes.LOCKED;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraStateManager extends CameraDevice.StateCallback {

    private static final String TAG = CameraStateManager.class.getName();

    private final CameraPreview mCameraPreview;

    private final CameraPicture mCameraPicture;

    private final CameraSession mCameraSession;

    private HandlerThread mBackgroundThread;

    private Handler mBackgroundHandler;

    private Semaphore mCameraOpenCloseLock = new Semaphore(1);

    private Context context;

    private CameraDevice mCameraDevice;

    private OnCameraState mOnCameraStateListener;

    private boolean opened;

    private String cameraId;


    public CameraStateManager(Context context, final CameraPreview mCameraPreview, final CameraPicture mCameraPicture, CameraSession cameraSession) {
        this.mCameraPreview = mCameraPreview;
        this.mCameraPicture = mCameraPicture;
        this.mCameraSession = cameraSession;
        this.context = context;
        this.opened = false;
    }

    public void startCamera(String cameraId) throws CameraManagerException {
        if(cameraId == null) {
            throw new RuntimeException("A cameraId must be selected");
        }
        this.cameraId = cameraId;
        startBackgroundThread();
        CameraManager manager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
        try {
            if (!mCameraOpenCloseLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                throw new CameraManagerException(LOCKED);
            }
            manager.openCamera(cameraId, this, null);
        } catch (CameraAccessException e) {
            Log.e(TAG, "CANNOT_OPEN_CAMERA: ", e);
            throw new CameraManagerException(CameraManagerException.Codes.CANNOT_OPEN_CAMERA, e);
        } catch (InterruptedException e) {
            Log.e(TAG, "INTERRUPTED: ", e);
            throw new CameraManagerException(CameraManagerException.Codes.INTERRUPTED, e);
        }
    }

    public void switchCamera(String cameraId, CameraCharacteristicsModel characteristicsModel) throws CameraManagerException {
        if(this.cameraId.equals(cameraId)) {
            return;
        }
        stopCamera();
        mCameraPreview.setCameraCharacteristics(characteristicsModel);
        startCamera(cameraId);
        mCameraPicture.refresh();
        Log.d(TAG, "switchCamera: finished");
    }

    public void stopCamera() {
        try {
            if(mCameraSession != null && mCameraSession.getCaptureSession() != null) {
                try {
                    mCameraSession.getCaptureSession().stopRepeating();
                    mCameraSession.getCaptureSession().abortCaptures();
                    mCameraSession.getCaptureSession().close();
                } catch (CameraAccessException | IllegalStateException e) {
                    Log.e(TAG, "close camera session: failed");
                }
            }
            if(mCameraPicture != null) {
                mCameraPicture.dispose();
            }
            if(mCameraPreview != null) {
                mCameraPreview.dispose();
            }
            if (mCameraDevice != null) {
                mCameraDevice.close();
                mCameraDevice = null;
            }
            releaseSemaphore();
        } catch (IllegalStateException e) {
            Log.e(TAG, "stopCamera: failed");
        } finally {
            mCameraOpenCloseLock.release();
            this.opened = false;
        }
    }

    public Handler getBackgroundThread() {
        return mBackgroundHandler;
    }


    @Override
    public void onOpened(@NonNull CameraDevice camera) {
        this.opened = true;
        this.mCameraDevice = camera;
        // init cameraPreview
        try {
            this.mCameraPreview.createCameraPreviewSession(mCameraDevice);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
        if(mOnCameraStateListener != null) {
            this.mOnCameraStateListener.onOpened();
        }
    }

    @Override
    public void onDisconnected(@NonNull CameraDevice camera) {
        stopCamera();
    }

    @Override
    public void onError(@NonNull CameraDevice camera, int error) {
        if(this.opened) {
            try {
                releaseSemaphore();
                mCameraPreview.dispose();
                this.startCamera(cameraId);
            } catch (CameraManagerException e) {
                Log.e(TAG, "Restarting camera after error: failed", e);
            }
        } else {
            stopCamera();
        }
        stopCamera();
    }

    public CameraDevice getCameraDevice() {
        return mCameraDevice;
    }

    public void dispose() {
        stopBackgroundThread();
    }

    // -----------------------------------------
    // Manage thread
    // -----------------------------------------

    private void startBackgroundThread() {
        if(mBackgroundThread != null) {
            return;
        }
        mBackgroundThread = new HandlerThread("CameraBackground");
        mBackgroundThread.start();
        mBackgroundHandler = new Handler(mBackgroundThread.getLooper());
    }

    private void stopBackgroundThread() {
        if(mBackgroundThread == null)
            return;
        mBackgroundThread.quitSafely();
        try {
            mBackgroundThread.join();
            mBackgroundThread = null;
            mBackgroundHandler = null;
        } catch (InterruptedException e) {
            Log.e(TAG, "stopBackgroundThread: ", e);
        }
    }

    private void releaseSemaphore() {
        if(this.mCameraOpenCloseLock != null)
            this.mCameraOpenCloseLock.release();
    }

    // -----------------------------------------
    /// OnStateCallback
    // -----------------------------------------

    public interface OnCameraState {

        void onOpened();
    }

}
