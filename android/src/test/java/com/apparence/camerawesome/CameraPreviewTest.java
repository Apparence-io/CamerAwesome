package com.apparence.camerawesome;

import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CaptureRequest;
import android.util.Size;
import android.view.Surface;

import com.apparence.camerawesome.models.FlashMode;
import com.apparence.camerawesome.surface.SurfaceFactory;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import io.flutter.view.TextureRegistry;

import static android.hardware.camera2.CaptureRequest.*;
import static android.hardware.camera2.CaptureRequest.FLASH_MODE;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
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
    SurfaceFactory surfaceFactoryMock;

    @Mock
    Surface surfaceMock;

    CameraSession cameraSession;

    CameraPreview cameraPreview;

    @Before
    public void setUp() throws Exception {
        reset(captureRequestBuilder);
        when(surfaceFactoryMock.build(any(Size.class))).thenReturn(surfaceMock);
        when(cameraDeviceMock.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)).thenReturn(captureRequestBuilder);
        cameraSession = new CameraSession();
        cameraPreview = new CameraPreview(
                cameraSession,
                null,
                surfaceFactoryMock,
                null,
                false);
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
        // check surfaces have been set
        Assert.assertEquals(cameraSession.getSurfaces().size(), 1);
        Assert.assertEquals(cameraSession.getCameraDevice(), cameraDeviceMock);
        Assert.assertNotNull(cameraSession.getCaptureSession());
    }

    @Test
    public void setFocusWithNoPreview()  {
        cameraPreview.setAutoFocus(true);
        verify(captureRequestBuilder, never()).set(eq(CaptureRequest.CONTROL_AF_MODE), Mockito.anyInt());
    }

    @Test
    public void setFocusWithPreview() throws CameraAccessException {
        cameraPreview.setPreviewSize(640, 480);
        cameraPreview.createCameraPreviewSession(cameraDeviceMock);
        reset(captureRequestBuilder);
        cameraPreview.setAutoFocus(true);
        verify(captureRequestBuilder, atLeastOnce()).set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
        reset(captureRequestBuilder);
        cameraPreview.setAutoFocus(false);
        verify(captureRequestBuilder, atLeastOnce()).set(eq(CaptureRequest.CONTROL_AF_MODE), eq(CONTROL_AF_MODE_OFF));
    }

    @Test
    public void setFlashMode() throws CameraAccessException {
        cameraPreview.setPreviewSize(640, 480);
        cameraPreview.createCameraPreviewSession(cameraDeviceMock);
        reset(captureRequestBuilder);
        cameraPreview.setFlashMode(FlashMode.NONE);
        verify(captureRequestBuilder, atLeastOnce()).set(FLASH_MODE, CaptureRequest.FLASH_MODE_OFF);
        reset(captureRequestBuilder);
        cameraPreview.setFlashMode(FlashMode.AUTO);
        verify(captureRequestBuilder, atLeastOnce()).set(eq(CaptureRequest.FLASH_MODE), eq(FLASH_MODE_SINGLE));
        cameraPreview.setFlashMode(FlashMode.ALWAYS);
        verify(captureRequestBuilder, atLeastOnce()).set(eq(CaptureRequest.FLASH_MODE), eq(FLASH_MODE_TORCH));
    }
}
