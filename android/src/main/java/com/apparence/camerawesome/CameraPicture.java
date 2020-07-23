package com.apparence.camerawesome;

import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureFailure;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.TotalCaptureResult;
import android.media.Image;
import android.media.ImageReader;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraPicture implements CameraSession.OnCaptureSession {

    private static String TAG = CameraPicture.class.getName();

    private final CameraSession mCameraSession;

    private CameraCaptureSession mCaptureSession;

    private ImageReader pictureImageReader;

    private Size size;

    public CameraPicture(CameraSession cameraSession) {
        this.mCameraSession = cameraSession;
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
        if (file.exists()) {
            //FIXME throw here
            return;
        }
        if(size == null) {
            //FIXME throw here
            return;
        }
        if(mCaptureSession == null) {
            //FIXME throw here
            Log.e(TAG, "takePicture: mCaptureSession is null");
            return;
        }
        pictureImageReader.setOnImageAvailableListener(
                new ImageReader.OnImageAvailableListener() {
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

//      FIXME pictureImageReader must be added to surfaces of camerasession
        CaptureRequest.Builder takePhotoRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
//        takePhotoRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_AUTO);
//        takePhotoRequestBuilder.set(CaptureRequest.CONTROL_AF_TRIGGER, CameraMetadata.CONTROL_AF_TRIGGER_START);
        takePhotoRequestBuilder.set(CaptureRequest.JPEG_ORIENTATION, orientation);
        takePhotoRequestBuilder.addTarget(pictureImageReader.getSurface());
        mCaptureSession.capture(takePhotoRequestBuilder.build(), mCaptureCallback, null);
    }

    public void setPreviewSession(CameraCaptureSession captureSession) {
        this.mCaptureSession = captureSession;
    }

    private void writeToFile(ByteBuffer buffer, File file) throws IOException {
        // outputstream is autoclosed by the try
        try (FileOutputStream outputStream = new FileOutputStream(file)) {
            while (0 < buffer.remaining()) {
                outputStream.getChannel().write(buffer);
            }
        }
    }

    private CameraCaptureSession.CaptureCallback mCaptureCallback = new CameraCaptureSession.CaptureCallback() {
        @Override
        public void onCaptureFailed(CameraCaptureSession session, CaptureRequest request, CaptureFailure failure) {
//            Log.d(TAG, "onCaptureFailed: ");
            super.onCaptureFailed(session, request, failure);
        }

        @Override
        public void onCaptureCompleted(CameraCaptureSession session, CaptureRequest request, TotalCaptureResult result) {
//            Log.d(TAG, "onCaptureCompleted: ");
            super.onCaptureCompleted(session, request, result);
        }

        @Override
        public void onCaptureProgressed(CameraCaptureSession session, CaptureRequest request, CaptureResult partialResult) {
//            Log.d(TAG, "onCaptureProgressed: ");
            super.onCaptureProgressed(session, request, partialResult);
        }

        @Override
        public void onCaptureStarted(CameraCaptureSession session, CaptureRequest request, long timestamp, long frameNumber) {
//            Log.d(TAG, "onCaptureStarted: ");
            super.onCaptureStarted(session, request, timestamp, frameNumber);
        }
    };

    // --------------------------------------------------
    // CameraSession.OnCaptureSession
    // --------------------------------------------------

    @Override
    public void onConfigured(@NonNull CameraCaptureSession session) {
        this.mCaptureSession = session;
    }

    @Override
    public void onConfigureFailed() {
        this.mCaptureSession = null;
    }

    // --------------------------------------------------
    // OnImageResult interface
    // --------------------------------------------------

    public interface OnImageResult {

        void onSuccess();

        void onFailure(String error);
    }

}
