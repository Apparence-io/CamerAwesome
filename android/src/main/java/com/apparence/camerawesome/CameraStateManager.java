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

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraStateManager extends CameraDevice.StateCallback {

    private static final String TAG = CameraStateManager.class.getName();

    private final CameraPreview mCameraPreview;

//    private CameraStateCallback mStateCallback;

    private HandlerThread mBackgroundThread;

    private Handler mBackgroundHandler;

    private Semaphore mCameraOpenCloseLock = new Semaphore(1);

    private Context context;

    private CameraDevice mCameraDevice;

    private OnCameraState mOnCameraStateListener;


    public CameraStateManager(Context context, CameraPreview mCameraPreview) {
        this.mCameraPreview = mCameraPreview;
        this.context = context;
    }

    public void startCamera(String cameraId) throws CameraManagerException {
        Log.d(TAG, "startCamera: 1");
        if(cameraId == null) {
            throw new RuntimeException("A cameraId must be selected");
        }
        Log.d(TAG, "startCamera: 2");
        startBackgroundThread();
        CameraManager manager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
        try {
            if (!mCameraOpenCloseLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                throw new RuntimeException("Time out waiting to lock camera opening.");
            }
            manager.openCamera(cameraId, this, mBackgroundHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, "CANNOT_OPEN_CAMERA: ", e);
            throw new CameraManagerException(CameraManagerException.Codes.CANNOT_OPEN_CAMERA, e);
        } catch (InterruptedException e) {
            Log.e(TAG, "INTERRUPTED: ", e);
            throw new CameraManagerException(CameraManagerException.Codes.INTERRUPTED, e);
        }
    }

    public void stopCamera() {
        Log.d(TAG, "stopCamera: ");
        try {
            mCameraOpenCloseLock.acquire();
            if(mCameraPreview != null)
                mCameraPreview.dispose();
            if (mCameraDevice != null) {
                mCameraDevice.close();
                mCameraDevice = null;
            }
            releaseSemaphore();
            stopBackgroundThread();
            Log.d(TAG, "... closed successfully");
        } catch (InterruptedException e) {
            throw new RuntimeException("Interrupted while trying to lock camera closing.", e);
        } finally {
            mCameraOpenCloseLock.release();
        }
    }

    public Handler getBackgroundThread() {
        return mBackgroundHandler;
    }


    @Override
    public void onOpened(@NonNull CameraDevice camera) {
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
        stopCamera();
    }

    public CameraDevice getCameraDevice() {
        return mCameraDevice;
    }

    // -----------------------------------------
    // Manage thread
    // -----------------------------------------

    private void startBackgroundThread() {
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
