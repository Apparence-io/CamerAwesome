package com.apparence.camerawesome;

import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CaptureRequest;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.Arrays;
import java.util.Collections;

import io.flutter.view.TextureRegistry;

import static android.hardware.camera2.CaptureRequest.*;
import static android.hardware.camera2.CaptureRequest.FLASH_MODE;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(MockitoJUnitRunner.class)
public class CameraPreviewTest {

    @Mock
    CameraDevice cameraDeviceMock;

    @Mock
    Builder captureRequestBuilder;

    @Mock
    TextureRegistry.SurfaceTextureEntry flutterTextureMock;

    @Mock
    SurfaceTexture surfaceTexture;

    CameraSession cameraSession;

    CameraPreview cameraPreview;

    @Before
    public void setUp() throws Exception {
        when(flutterTextureMock.surfaceTexture()).thenReturn(surfaceTexture);
        when(cameraDeviceMock.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)).thenReturn(captureRequestBuilder);
        cameraSession = new CameraSession();
        cameraPreview = new CameraPreview(cameraSession, flutterTextureMock);
        cameraSession.setOnCaptureSessionListenerList(
                Collections.<CameraSession.OnCaptureSession>singletonList(cameraPreview));
    }

    @Test
    public void createPreviewSession() throws CameraAccessException {
        cameraPreview.setPreviewSize(640, 480);
        cameraPreview.createCameraPreviewSession(cameraDeviceMock);
        Assert.assertNotNull(cameraPreview.getPreviewRequest());
        // Flash is disabled by default
        verify(captureRequestBuilder, times(1))
                .set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF);
        // AutoFocus is activated by default
        verify(captureRequestBuilder, times(1))
                .set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
        // Android preview stays on portrait mode
        verify(captureRequestBuilder, times(1))
                .set(CaptureRequest.JPEG_ORIENTATION, 270);

    }

//    public void setFlashWithNoPreview() {
//        cameraPreview.setAutoFocus(true);
//
//    }

//    public void setFlashWithPreview() {
//        cameraPreview.setAutoFocus(true);
//
//    }
}
