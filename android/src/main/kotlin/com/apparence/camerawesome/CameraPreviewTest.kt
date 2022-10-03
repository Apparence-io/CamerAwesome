//package com.apparence.camerawesome
//
//import android.hardware.camera2.CameraAccessException
//import android.hardware.camera2.CameraDevice
//import android.hardware.camera2.CameraMetadata
//import android.hardware.camera2.CaptureRequest
//import android.util.Size
//import android.view.Surface
//import com.apparence.camerawesome.models.FlashMode
//import com.apparence.camerawesome.surface.SurfaceFactory
//import org.junit.Assert
//import org.junit.Before
//import org.junit.Test
//import org.junit.runner.RunWith
//import java.lang.Exception
//
//@RunWith(MockitoJUnitRunner::class)
//class CameraPreviewTest {
//    @Mock
//    var cameraDeviceMock: CameraDevice? = null
//
//    @Mock
//    var captureRequestBuilder: CaptureRequest.Builder? = null
//
//    @Mock
//    var surfaceFactoryMock: SurfaceFactory? = null
//
//    @Mock
//    var surfaceMock: Surface? = null
//    var cameraSession: CameraSession? = null
//    var cameraPreview: CameraPreview? = null
//    @Before
//    @Throws(Exception::class)
//    fun setUp() {
//        Mockito.reset(captureRequestBuilder)
//        Mockito.`when`(surfaceFactoryMock.build(ArgumentMatchers.any(Size::class.java)))
//            .thenReturn(surfaceMock)
//        Mockito.`when`(cameraDeviceMock!!.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW))
//            .thenReturn(captureRequestBuilder)
//        cameraSession = CameraSession()
//        cameraPreview = CameraPreview(
//            cameraSession,
//            null,
//            surfaceFactoryMock,
//            null,
//            false
//        )
//        cameraSession!!.onCaptureSessionListenerList = listOf(cameraPreview)
//    }
//
//    @Test
//    @Throws(CameraAccessException::class)
//    fun createPreviewSession() {
//        cameraPreview!!.setPreviewSize(640, 480)
//        cameraPreview!!.createCameraPreviewSession(cameraDeviceMock)
//        Assert.assertNotNull(cameraPreview!!.previewRequest)
//        // Flash is disabled by default
//        Mockito.verify(captureRequestBuilder, Mockito.times(1))
//            .set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF)
//        // AutoFocus is activated by default
//        Mockito.verify(captureRequestBuilder, Mockito.times(1))
//            .set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
//        // Android preview stays on portrait mode
//        Mockito.verify(captureRequestBuilder, Mockito.times(1))
//            .set(CaptureRequest.JPEG_ORIENTATION, 270)
//        // check surfaces have been set
//        Assert.assertEquals(cameraSession!!.surfaces.size.toLong(), 1)
//        Assert.assertEquals(cameraSession!!.cameraDevice, cameraDeviceMock)
//        Assert.assertNotNull(cameraSession!!.captureSession)
//    }
//
//    @Test
//    fun setFocusWithNoPreview() {
//        cameraPreview!!.setAutoFocus(true)
//        Mockito.verify(captureRequestBuilder, Mockito.never()).set(
//            ArgumentMatchers.eq(
//                CaptureRequest.CONTROL_AF_MODE
//            ), Mockito.anyInt()
//        )
//    }
//
//    @Test
//    @Throws(CameraAccessException::class)
//    fun setFocusWithPreview() {
//        cameraPreview!!.setPreviewSize(640, 480)
//        cameraPreview!!.createCameraPreviewSession(cameraDeviceMock)
//        Mockito.reset(captureRequestBuilder)
//        cameraPreview!!.setAutoFocus(true)
//        Mockito.verify(captureRequestBuilder, Mockito.atLeastOnce())
//            .set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
//        Mockito.reset(captureRequestBuilder)
//        cameraPreview!!.setAutoFocus(false)
//        Mockito.verify(captureRequestBuilder, Mockito.atLeastOnce()).set(
//            ArgumentMatchers.eq(
//                CaptureRequest.CONTROL_AF_MODE
//            ), ArgumentMatchers.eq(CameraMetadata.CONTROL_AF_MODE_OFF)
//        )
//    }
//
//    @Test
//    @Throws(CameraAccessException::class)
//    fun setFlashMode() {
//        cameraPreview!!.setPreviewSize(640, 480)
//        cameraPreview!!.createCameraPreviewSession(cameraDeviceMock)
//        Mockito.reset(captureRequestBuilder)
//        cameraPreview!!.setFlashMode(FlashMode.NONE)
//        Mockito.verify(captureRequestBuilder, Mockito.atLeastOnce())
//            .set(CaptureRequest.FLASH_MODE, CaptureRequest.FLASH_MODE_OFF)
//        Mockito.reset(captureRequestBuilder)
//        cameraPreview!!.setFlashMode(FlashMode.AUTO)
//        Mockito.verify(captureRequestBuilder, Mockito.atLeastOnce()).set(
//            ArgumentMatchers.eq(
//                CaptureRequest.FLASH_MODE
//            ), ArgumentMatchers.eq(CameraMetadata.FLASH_MODE_SINGLE)
//        )
//        cameraPreview!!.setFlashMode(FlashMode.ALWAYS)
//        Mockito.verify(captureRequestBuilder, Mockito.atLeastOnce()).set(
//            ArgumentMatchers.eq(
//                CaptureRequest.FLASH_MODE
//            ), ArgumentMatchers.eq(CameraMetadata.FLASH_MODE_TORCH)
//        )
//    }
//}