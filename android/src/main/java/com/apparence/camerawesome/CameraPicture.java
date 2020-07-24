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

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

import static com.apparence.camerawesome.CameraPictureStates.STATE_READY_AFTER_FOCUS;
import static com.apparence.camerawesome.CameraPictureStates.STATE_RELEASE_FOCUS;
import static com.apparence.camerawesome.CameraPictureStates.STATE_REQUEST_PHOTO_AFTER_FOCUS;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraPicture implements CameraSession.OnCaptureSession {

    private static String TAG = CameraPicture.class.getName();

    private final CameraSession mCameraSession;

    private ImageReader pictureImageReader;

    private Size size;

    private boolean autoFocus;

    private boolean autoExposure;

    private boolean autoFlash;

    private CaptureRequest.Builder takePhotoRequestBuilder;

    private int orientation;

    public CameraPicture(CameraSession cameraSession) {
        this.mCameraSession = cameraSession;
        this.autoFocus = true;
        this.autoFlash = true;
    }

    /**
     * captureSize size of photo to use (must be in the available set of size) use CameraSetup to get all
     * @param width
     * @param height
     */
    public void setSize(int width, int height) {
        this.size = new Size(width, height);
        pictureImageReader = ImageReader.newInstance(size.getWidth(), size.getHeight(), ImageFormat.JPEG, 2);
        mCameraSession.addSurface(pictureImageReader.getSurface());
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
                        try (Image image = reader.acquireLatestImage()) {
                            ByteBuffer buffer = image.getPlanes()[0].getBuffer();
                            CameraPicture.this.writeToFile(buffer, file);
                            onResultListener.onSuccess();
                        } catch (IOException e) {
                            onResultListener.onFailure("IOError");
                        }
                    }
                }, null);

        takePhotoRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
        takePhotoRequestBuilder.addTarget(pictureImageReader.getSurface());
        takePhotoRequestBuilder.set(CaptureRequest.FLASH_MODE, autoFlash ? CaptureRequest.FLASH_MODE_TORCH : CaptureRequest.FLASH_MODE_OFF);
        takePhotoRequestBuilder.set(CaptureRequest.JPEG_ORIENTATION, orientation);
        takePhotoRequestBuilder.set(CaptureRequest.CONTROL_MODE, CaptureRequest.CONTROL_MODE_AUTO);
        mCameraSession.getCaptureSession().capture(takePhotoRequestBuilder.build(), mCaptureCallback, null);
    }

    public void setAutoExposure(boolean autoExposure) {
        this.autoExposure = autoExposure;
    }

    public void setAutoFlash(boolean autoFlash) {
        this.autoFlash = autoFlash;
    }


    public void setAutoFocus(boolean autoFocus) {
        this.autoFocus = autoFocus;
    }


    public boolean isAutoFocus() {
        return autoFocus;
    }

    // ---------------------------------------------------
    // PRIVATES
    // ---------------------------------------------------

    private CameraCaptureSession.CaptureCallback mCaptureCallback = new CameraCaptureSession.CaptureCallback() {
        @Override
        public void onCaptureCompleted(CameraCaptureSession session, CaptureRequest request, TotalCaptureResult result) {
        }

        @Override
        public void onCaptureProgressed(CameraCaptureSession session, CaptureRequest request, CaptureResult partialResult) {
        }
    };


    private void refreshFocus() {
        final CaptureRequest.Builder captureBuilder;
        try {
            //FIXME change to takePhotoRequestBuilder
            captureBuilder = mCameraSession.getCameraDevice().createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
            captureBuilder.addTarget(pictureImageReader.getSurface());
            captureBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
            captureBuilder.set(CaptureRequest.FLASH_MODE, autoFlash ? CaptureRequest.FLASH_MODE_TORCH : CaptureRequest.FLASH_MODE_OFF);
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
        if(state.equals(STATE_REQUEST_PHOTO_AFTER_FOCUS)) {

        } else if(state.equals(STATE_READY_AFTER_FOCUS)) {
            refreshFocus();
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
