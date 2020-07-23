package com.apparence.camerawesome;

import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
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
import android.util.Size;
import android.util.Log;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.Semaphore;

import io.flutter.view.TextureRegistry;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CameraPreview implements CameraSession.OnCaptureSession  {

    private static final String TAG = CameraPreview.class.getName();

    private final CameraSession mCameraSession;

    private TextureRegistry.SurfaceTextureEntry flutterTexture;

    private Size previewSize;

    private ImageReader mImageReader;

    private Handler mBackgroundHandler;

    private Handler uiThreadHandler = new Handler(Looper.getMainLooper());

    private CaptureRequest.Builder mPreviewRequestBuilder;

    private CameraCaptureSession mCaptureSession;

    private CaptureRequest mPreviewRequest;


    public CameraPreview(CameraSession cameraSession) {
        this.mCameraSession = cameraSession;
    }


    void createCameraPreviewSession(final CameraDevice cameraDevice) throws CameraAccessException {
        // create image reader
        mImageReader = ImageReader.newInstance(previewSize.getWidth(), previewSize.getHeight(), ImageFormat.JPEG, 2);
        _createImageReader();
        // create surface
        SurfaceTexture surfaceTexture = flutterTexture.surfaceTexture();
        surfaceTexture.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
        Surface flutterSurface = new Surface(surfaceTexture);
        // create preview
        mPreviewRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
//        mPreviewRequestBuilder.addTarget(mImageReader.getSurface());
        mPreviewRequestBuilder.addTarget(flutterSurface);
//        List<Surface> surfaces = Arrays.asList(flutterSurface, mImageReader.getSurface());
//        List<Surface> surfaces = Arrays.asList(flutterSurface);
        mCameraSession.addSurface(flutterSurface);
        mCameraSession.createCameraCaptureSession(cameraDevice);
    }
    
    public CameraCaptureSession getCaptureSession() {
        return mCaptureSession;
    }

    public void setFlutterTexture(TextureRegistry.SurfaceTextureEntry flutterTexture) {
        this.flutterTexture = flutterTexture;
    }

    public Long getFlutterTexture() {
        return this.flutterTexture.id();
    }

    public void dispose() {
//        cancelStream();
        mImageReader.close();
        if(mCaptureSession != null) {
            mCaptureSession.close();
        }
    }

    public void setPreviewSize(int width, int height) {
        this.previewSize = new Size(width, height);
    }

    // --------------------------------------------------
    // CameraSession.OnCaptureSession
    // --------------------------------------------------

    @Override
    public void onConfigured(@NonNull CameraCaptureSession session) {
        mCaptureSession = session;
        try {
            mPreviewRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
            mPreviewRequestBuilder.set(CaptureRequest.JPEG_ORIENTATION, 270);
            mPreviewRequest = mPreviewRequestBuilder.build();
            mCaptureSession.setRepeatingRequest(mPreviewRequest, null, mBackgroundHandler);
        } catch (CameraAccessException e) {
            Log.e(TAG, "onConfigureSession", e);
        }
    }

    @Override
    public void onConfigureFailed() {
        this.mCaptureSession = null;
    }


    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    private void _createImageReader() {
        ImageReader.OnImageAvailableListener mOnImageAvailableListener = new ImageReader.OnImageAvailableListener() {
            @Override
            public void onImageAvailable(ImageReader reader) {
                try {
                    Image img = reader.acquireLatestImage();
                    if(img == null) {
                        return;
                    }
//                    if(events != null) {
//                        ByteBuffer buffer = img.getPlanes()[0].getBuffer();
//
//                        final byte[] bytes = new byte[buffer.capacity()];
//                        buffer.get(bytes);
//                        sendData(bytes);
//                        return;
//                    }
                    img.close();
                    //Bitmap bitmapImage = BitmapFactory.decodeByteArray(bytes, 0, bytes.length, null);
                    //previewObs.onNext(img);
                } catch (Exception e) {
                    Log.e(TAG, "onImageAvailable: Error", e);
                }
            }
        };
        mImageReader.setOnImageAvailableListener(mOnImageAvailableListener, mBackgroundHandler);
    }


//    private void sendImageFormat(final Image img) {
//        Runnable sendDataRunner = new Runnable() {
//            @Override
//            public void run() {
//                HashMap<String, Object> map = new HashMap<>();
//                map.put("height", img.getHeight());
//                map.put("width", img.getWidth());
//                events.success(map);
//            }
//        };
//        uiThreadHandler.post(sendDataRunner);
//    }
//
//
//    private void sendData(final byte[] bytes) {
//        Runnable sendDataRunner = new Runnable() {
//            @Override
//            public void run() {
//                if (bytes.length > 0) {
//                    HashMap<String, Object> map = new HashMap<>();
//                    map.put("data", bytes);
//                    events.success(map);
//                }
//            }
//        };
//        uiThreadHandler.post(sendDataRunner);
//    }



}


