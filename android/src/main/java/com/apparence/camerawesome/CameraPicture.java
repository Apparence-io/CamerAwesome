package com.apparence.camerawesome;

import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.TotalCaptureResult;
import android.media.Image;
import android.media.ImageReader;
import android.os.Build;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.apparence.camerawesome.models.CameraCharacteristicsModel;
import com.apparence.camerawesome.models.FlashMode;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

import static com.apparence.camerawesome.CameraPictureStates.STATE_PRECAPTURE;
import static com.apparence.camerawesome.CameraPictureStates.STATE_READY_AFTER_FOCUS;
import static com.apparence.camerawesome.CameraPictureStates.STATE_RELEASE_FOCUS;
import static com.apparence.camerawesome.CameraPictureStates.STATE_REQUEST_PHOTO_AFTER_FOCUS;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraPicture implements CameraSession.OnCaptureSession {

    private static String TAG = CameraPicture.class.getName();

    private final CameraSession mCameraSession;

    private final CameraCharacteristicsModel mCameraCharacteristics;

    private CameraDevice mCameraDevice;

    private ImageReader pictureImageReader;

    private Size size;

    private boolean autoFocus;

    private CaptureRequest.Builder takePhotoRequestBuilder;

    private int orientation;

    private FlashMode flashMode;

    public CameraPicture(CameraSession cameraSession, final CameraCharacteristicsModel cameraCharacteristics) {
        mCameraSession = cameraSession;
        mCameraCharacteristics = cameraCharacteristics;
        flashMode = FlashMode.NONE;
        setAutoFocus(true);
    }

    /**
     * captureSize size of photo to use (must be in the available set of size) use CameraSetup to get all
     * @param width
     * @param height
     */
    public void setSize(int width, int height) {
        this.size = new Size(width, height);
        refresh();
    }

    public void refresh() {
        pictureImageReader = ImageReader.newInstance(size.getWidth(), size.getHeight(), ImageFormat.JPEG, 2);
        mCameraSession.addPictureSurface(pictureImageReader.getSurface());
    }

    /**
     * Takes a picture from the current device
     * @param cameraDevice the cameraDevice that
     * @param filePath the path where to save the picture
     * @param orientation orientation to use to save the image
     * @param onResultListener fires on success / failure
     * @throws CameraAccessException if camera is not available
     */
    public void takePicture(final CameraDevice cameraDevice, final String filePath, final int orientation, final OnImageResult onResultListener) throws CameraAccessException {
        final File file = new File(filePath);
        this.mCameraDevice = cameraDevice;
        this.orientation = orientation;
        if (file.exists()) {
            //FIXME throw here
            return;
        }
        if(size == null) {
            //FIXME throw here
            return;
        }
        if(mCameraSession.getCaptureSession() == null) {
            //FIXME throw here
            Log.e(TAG, "takePicture: mCameraSession.getCaptureSession() is null");
            return;
        }
        pictureImageReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
            @Override
            public void onImageAvailable(ImageReader reader) {
                try (Image image = reader.acquireNextImage()) {
                    ByteBuffer buffer = image.getPlanes()[0].getBuffer();
                    CameraPicture.this.writeToFile(buffer, file);
                    onResultListener.onSuccess();
                } catch (IOException e) {
                    onResultListener.onFailure("IOError");
                }
            }
        }, null);
        if(autoFocus) {
            mCameraSession.setState(CameraPictureStates.STATE_REQUEST_FOCUS);
        } else {
            captureStillPicture();
        }
    }

    public void setFlashMode(FlashMode flashMode) {
        if(!mCameraCharacteristics.hasFlashAvailable()) {
            return;
        }
        this.flashMode = flashMode;
    }

    public void setAutoFocus(boolean autoFocus) {
        this.autoFocus = autoFocus && mCameraCharacteristics.hasAutoFocus();
    }

    public void dispose() {
        if(pictureImageReader != null) {
            pictureImageReader.close();
            pictureImageReader = null;
        }
    }

    // ---------------------------------------------------
    // PRIVATES
    // ---------------------------------------------------

    private void captureStillPicture() throws CameraAccessException {
        takePhotoRequestBuilder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
        takePhotoRequestBuilder.addTarget(pictureImageReader.getSurface());
        switch (flashMode) {
            case NONE:
                takePhotoRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON);
                takePhotoRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF);
                break;
            case ON:
                takePhotoRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_ALWAYS_FLASH);
                break;
            case AUTO:
                takePhotoRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH);
                break;
            case ALWAYS:
                takePhotoRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_TORCH);
                takePhotoRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON);
                break;
        }
        takePhotoRequestBuilder.set(CaptureRequest.JPEG_ORIENTATION, orientation);
        mCameraSession.getCaptureSession().stopRepeating();
        mCameraSession.getCaptureSession().capture(takePhotoRequestBuilder.build(), mCaptureCallback, null);
    }

    private CameraCaptureSession.CaptureCallback mCaptureCallback = new CameraCaptureSession.CaptureCallback() {
        @Override
        public void onCaptureCompleted(CameraCaptureSession session, CaptureRequest request, TotalCaptureResult result) {
            if(mCameraSession.getState() != null && mCameraSession.getState().equals(STATE_REQUEST_PHOTO_AFTER_FOCUS)) {
                mCameraSession.setState(STATE_RELEASE_FOCUS);
            } else {
                mCameraSession.setState(CameraPictureStates.STATE_RESTART_PREVIEW_REQUEST);
            }
        }
    };

    private void refreshFocus() {
        final CaptureRequest.Builder captureBuilder;
        try {
            captureBuilder = mCameraSession.getCameraDevice().createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
            captureBuilder.addTarget(pictureImageReader.getSurface());
            captureBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
            if (flashMode == FlashMode.AUTO) {
                takePhotoRequestBuilder.set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_SINGLE);
            }
            captureBuilder.set(CaptureRequest.JPEG_ORIENTATION, orientation);

            CameraCaptureSession.CaptureCallback CaptureCallback = new CameraCaptureSession.CaptureCallback() {
                @Override
                public void onCaptureCompleted(@NonNull CameraCaptureSession session,
                                               @NonNull CaptureRequest request,
                                               @NonNull TotalCaptureResult result) {
                    mCameraSession.setState(STATE_RELEASE_FOCUS);
                }
            };
            mCameraSession.getCaptureSession().stopRepeating();
            mCameraSession.getCaptureSession().abortCaptures();
            mCameraSession.getCaptureSession().capture(captureBuilder.build(), CaptureCallback, null);
        } catch (CameraAccessException e) {
            Log.e(TAG, "refreshFocus: ", e);
            e.printStackTrace();
        }
    }

    private void writeToFile(ByteBuffer buffer, File file) throws IOException {
        // outputstream is autoclosed by the try
        try (FileOutputStream outputStream = new FileOutputStream(file)) {
            while (0 < buffer.remaining()) {
                outputStream.getChannel().write(buffer);
            }
        }
    }

    // --------------------------------------------------
    // CameraSession.OnCaptureSession
    // --------------------------------------------------

    @Override
    public void onConfigured(@NonNull CameraCaptureSession session) {
        this.mCameraSession.setCaptureSession(session);
    }

    @Override
    public void onConfigureFailed() {
        this.mCameraSession.setCaptureSession(null);
    }

    @Override
    public void onStateChanged(CameraPictureStates state) {
        if(state == null) {
            return;
        }
        try {
            switch (state) {
                case STATE_REQUEST_PHOTO_AFTER_FOCUS:
                    captureStillPicture();
                    break;
                case STATE_READY_AFTER_FOCUS:
                    refreshFocus();
                    break;
            }
        } catch (CameraAccessException e) {
            Log.e(TAG, "onStateChanged: ", e);
        }
    }

    // --------------------------------------------------
    // OnImageResult interface
    // --------------------------------------------------

    public interface OnImageResult {

        void onSuccess();

        void onFailure(String error);
    }

}
