package com.apparence.camerawesome;

import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureFailure;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.TotalCaptureResult;
import android.os.Build;
import android.os.Handler;
import android.util.Size;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;

import com.apparence.camerawesome.models.CameraCharacteristicsModel;
import com.apparence.camerawesome.models.FlashMode;
import com.apparence.camerawesome.surface.SurfaceFactory;

import static com.apparence.camerawesome.CameraPictureStates.STATE_PRECAPTURE;
import static com.apparence.camerawesome.CameraPictureStates.STATE_REQUEST_PHOTO_AFTER_FOCUS;
import static com.apparence.camerawesome.CameraPictureStates.STATE_RESTART_PREVIEW_REQUEST;
import static com.apparence.camerawesome.CameraPictureStates.STATE_READY_AFTER_FOCUS;
import static com.apparence.camerawesome.CameraPictureStates.STATE_RELEASE_FOCUS;
import static com.apparence.camerawesome.CameraPictureStates.STATE_WAITING_LOCK;
import static com.apparence.camerawesome.CameraPictureStates.STATE_WAITING_PRECAPTURE_READY;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraPreview implements CameraSession.OnCaptureSession  {

    private static final String TAG = CameraPreview.class.getName();

    public static final int MAX_PREVIEW_WIDTH = 1920;

    public static final int MAX_PREVIEW_HEIGHT = 1080;

    private final CameraSession mCameraSession;

    private final SurfaceFactory surfaceFactory;

    private Size previewSize;

    private Handler mBackgroundHandler;

    private CaptureRequest.Builder mPreviewRequestBuilder;

    private CameraCaptureSession mCaptureSession;

    private CaptureRequest mPreviewRequest;

    private boolean autoFocus;

    private FlashMode flashMode;

    private float mZoom;

    private Rect mInitialCropRegion;

    private CameraCharacteristicsModel cameraCharacteristics;

    private Surface previewSurface;

    private SurfaceTexture surfaceTexture;

    private int orientation;


    public CameraPreview(final CameraSession cameraSession, final CameraCharacteristicsModel cameraCharacteristics, final SurfaceFactory surfaceFactory) {
        this.autoFocus = true;
        this.flashMode = FlashMode.NONE;
        this.mCameraSession = cameraSession;
        this.cameraCharacteristics = cameraCharacteristics;
        this.surfaceFactory = surfaceFactory;
        this.orientation = 270;
    }
    
    void createCameraPreviewSession(final CameraDevice cameraDevice) throws CameraAccessException {
        if(previewSize == null)
            this.previewSize = new Size(MAX_PREVIEW_WIDTH, MAX_PREVIEW_HEIGHT);
        // create surface
        previewSurface = surfaceFactory.build(previewSize);
        // create preview
        mPreviewRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
        // save initial region for zoom management
        mInitialCropRegion = mPreviewRequestBuilder.get(CaptureRequest.SCALER_CROP_REGION);
        initPreviewRequest();

        mPreviewRequestBuilder.addTarget(previewSurface);
        mCameraSession.addPreviewSurface(previewSurface);
        mCameraSession.createCameraCaptureSession(cameraDevice);
    }

    public void lockFocus() {
        mCameraSession.setState(STATE_WAITING_LOCK);
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_START);
        try {
            mCaptureSession.capture(mPreviewRequestBuilder.build(), mCaptureFocusedCallback,null);
        } catch (CameraAccessException e) {
            Log.e(TAG, "lockFocus: error ", e);
        }
    }

    public void unlockFocus() {
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_CANCEL);
        mCameraSession.setState(null);
        try {
            mCaptureSession.capture(mPreviewRequestBuilder.build(), mCaptureFocusedCallback, null);
            initPreviewRequest();
            refreshConfiguration();
        } catch (CameraAccessException e) {
            Log.e(TAG, "unlockFocus: ", e);
        }
    }
    
    public CameraCaptureSession getCaptureSession() {
        return mCaptureSession;
    }

    public Long getFlutterTexture() {
        if(this.surfaceFactory == null) {
            throw new RuntimeException("surface factory null");
        }
        return this.surfaceFactory.getSurfaceId();
    }

    public void dispose() {
        if(mCaptureSession != null) {
            // release surface
            mCameraSession.clearSurface();
            previewSurface.release();
            mCaptureSession.close();
        }
    }

    public void setPreviewSize(int width, int height) {
        if(width > MAX_PREVIEW_WIDTH || height > MAX_PREVIEW_HEIGHT) {
            this.previewSize = new Size(1920, 1080);
        } else {
            this.previewSize = new Size(width, height);
        }
    }

    public Size getPreviewSize() {
        return this.previewSize;
    }

    public void setCameraCharacteristics(CameraCharacteristicsModel cameraCharacteristics) {
        this.cameraCharacteristics = cameraCharacteristics;
    }

    public void setAutoFocus(boolean autoFocus) {
        this.autoFocus = autoFocus;
        initPreviewRequest();
        refreshConfiguration();
    }

    public void setFlashMode(FlashMode flashMode) {
        this.flashMode = flashMode;
        initPreviewRequest();
        refreshConfiguration();
    }

    public void setZoom(float zoom) {
        this.mZoom = zoom;
        updateZoom();
        refreshConfiguration();
    }

    // ------------------------------------------------------
    // PRIVATES
    // ------------------------------------------------------

    private void initPreviewRequest() {
        if(mPreviewRequestBuilder == null) {
            return;
        }
        mPreviewRequestBuilder.set(CaptureRequest.JPEG_ORIENTATION, orientation);
        switch (flashMode) {
            case ON:
                mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_ALWAYS_FLASH);
                mPreviewRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF);
                break;
            case AUTO:
                mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH);
                mPreviewRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF);
                break;
            case ALWAYS:
                mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON);
                mPreviewRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_TORCH);
                break;
            case NONE:
                mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON);
                mPreviewRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF);
                break;
            default:
                mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_ALWAYS_FLASH);
                mPreviewRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF);
                break;
        }
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE, this.autoFocus
                ? CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
                : CaptureRequest.CONTROL_AF_MODE_OFF);

    }

    private void refreshConfiguration() {
        if(mCaptureSession == null) {
            return;
        }
        try {
            mCaptureSession.setRepeatingRequest(mPreviewRequestBuilder.build(), mCaptureFocusedCallback, null);
        } catch (CameraAccessException | IllegalStateException | IllegalArgumentException e) {
            Log.e(TAG, "refreshConfiguration", e);
        }
    }

    //FIXME
    private void refreshConfigurationWithCallback() {
        try {
            mCaptureSession.capture(mPreviewRequestBuilder.build(), null, mBackgroundHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, "refreshConfigurationWithCallback", e);
        }
    }

    // Inspired by react nativ plugin
    private void updateZoom() {
        float maxZoom = this.cameraCharacteristics.getMaxZoom();
        Rect currentPreviewArea = this.cameraCharacteristics.getAvailablePreviewZone();
        if(currentPreviewArea == null) {
            return;
        }
        float scaledZoom = mZoom * (maxZoom - 1.0f) + 1.0f;
        int currentWidth = currentPreviewArea.width();
        int currentHeight = currentPreviewArea.height();
        int zoomedWidth = (int) (currentWidth / scaledZoom);
        int zoomedHeight = (int) (currentHeight / scaledZoom);
        int widthOffset = (currentWidth - zoomedWidth) / 2;
        int heightOffset = (currentHeight - zoomedHeight) / 2;

        Rect zoomPreviewArea = new Rect(
                currentPreviewArea.left + widthOffset,
                currentPreviewArea.top + heightOffset,
                currentPreviewArea.right - widthOffset,
                currentPreviewArea.bottom - heightOffset
        );
        // ¯\_(ツ)_/¯ for some devices calculating the Rect for zoom=1 results in a bit different
        // Rect that device claims as its no-zoom crop region and the preview freezes
        if (scaledZoom != 1.0f) {
            mPreviewRequestBuilder.set(CaptureRequest.SCALER_CROP_REGION, zoomPreviewArea);
        } else {
            mPreviewRequestBuilder.set(CaptureRequest.SCALER_CROP_REGION, mInitialCropRegion);
        }
    }

    // --------------------------------------------------
    // CameraSession.OnCaptureSession
    // --------------------------------------------------

    @Override
    public void onConfigured(@NonNull CameraCaptureSession session) {
        mCaptureSession = session;
        refreshConfiguration();
    }

    @Override
    public void onConfigureFailed() {
        this.mCaptureSession = null;
    }

    @Override
    public void onStateChanged(CameraPictureStates state) {
        if(state == null)
            return;
        switch (state) {
            case STATE_RELEASE_FOCUS:
                this.unlockFocus();
                break;
            case STATE_REQUEST_FOCUS:
                this.lockFocus();
                break;
            case STATE_RESTART_PREVIEW_REQUEST:
                this.refreshConfiguration();
                break;
            case STATE_PRECAPTURE:
                this.runPrecaptureSequence();
                break;
        }
    }

    // ------------------------------------------------------
    // ON FOCUS CALLBACK
    // ------------------------------------------------------

    private void runPrecaptureSequence() {
        mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER, CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER_START);
        try {
            mCaptureSession.capture(mPreviewRequestBuilder.build(), mCaptureFocusedCallback , null);
            mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER, CaptureRequest.CONTROL_AE_PRECAPTURE_TRIGGER_IDLE);
        } catch (CameraAccessException e) {
            Log.e(TAG, "Failed to run precapture sequence.", e);
        }
    }

    private CameraCaptureSession.CaptureCallback mCaptureFocusedCallback = new CameraCaptureSession.CaptureCallback() {
        @Override
        public void onCaptureCompleted(CameraCaptureSession session, CaptureRequest request, TotalCaptureResult result) {
            processCapture(result);
        }

        @Override
        public void onCaptureProgressed(CameraCaptureSession session, CaptureRequest request, CaptureResult partialResult) {
            processCapture(partialResult);
        }
    };

    private void processCapture(CaptureResult result) {
        if(mCameraSession.getState() == null) {
            return;
        }
        switch (mCameraSession.getState()) {
            case STATE_WAITING_LOCK:
                Integer afState = result.get(CaptureResult.CONTROL_AF_STATE);
                if(afState == null) {
                    return;
                } else if (CaptureResult.CONTROL_AF_STATE_FOCUSED_LOCKED == afState ||
                        afState == CaptureResult.CONTROL_AF_STATE_NOT_FOCUSED_LOCKED) {
                    // CONTROL_AE_STATE can be null on some devices
                    Integer aeState = result.get(CaptureResult.CONTROL_AE_STATE);
                    if (aeState == null || aeState == CaptureResult.CONTROL_AE_STATE_CONVERGED) {
                        mCameraSession.setState(STATE_REQUEST_PHOTO_AFTER_FOCUS);
                    } else {
                        mCameraSession.setState(STATE_PRECAPTURE);
                    }
                }
                break;
            case STATE_PRECAPTURE: {
                Integer ae = result.get(CaptureResult.CONTROL_AE_STATE);
                if (ae == null || ae == CaptureResult.CONTROL_AE_STATE_PRECAPTURE ||
                        ae == CaptureRequest.CONTROL_AE_STATE_FLASH_REQUIRED ||
                        ae == CaptureResult.CONTROL_AE_STATE_CONVERGED) {
                    mCameraSession.setState(STATE_WAITING_PRECAPTURE_READY);
                }
                break;
            }
            case STATE_WAITING_PRECAPTURE_READY: {
                Integer ae = result.get(CaptureResult.CONTROL_AE_STATE);
                if (ae == null || ae != CaptureResult.CONTROL_AE_STATE_PRECAPTURE) {
                    mCameraSession.setState(STATE_REQUEST_PHOTO_AFTER_FOCUS);
                }
                break;
            }
        }
    }

    // ------------------------------------------------------
    // VISIBLE FOR TESTS
    // ------------------------------------------------------

    @VisibleForTesting
    public CaptureRequest.Builder getPreviewRequest() {
        return mPreviewRequestBuilder;
    }
}


