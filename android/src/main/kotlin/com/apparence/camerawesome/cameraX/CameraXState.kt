package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context.CAMERA_SERVICE
import android.graphics.Rect
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import android.util.Log
import android.util.Size
import android.view.Surface
import androidx.camera.camera2.internal.compat.CameraCharacteristicsCompat
import androidx.camera.camera2.internal.compat.quirk.CamcorderProfileResolutionQuirk
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.*
import androidx.camera.core.internal.utils.ImageUtil
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.camera.video.VideoCapture
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.apparence.camerawesome.models.FlashMode
import io.flutter.plugin.common.EventChannel
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executor

/// Hold the settings of the camera and use cases in this class and
/// call updateLifecycle() to refresh the state
data class CameraXState(
    val textureRegistry: TextureRegistry,
    val textureEntry: TextureRegistry.SurfaceTextureEntry,
    var imageCapture: ImageCapture? = null,
    var cameraSelector: CameraSelector,
    private var recorder: Recorder? = null,
    var videoCapture: VideoCapture<Recorder>? = null,

    var preview: Preview? = null,
    var previewCamera: Camera? = null,
    private var cameraProvider: ProcessCameraProvider,
    private var currentCaptureMode: CaptureModes,
    var enableAudioRecording: Boolean = true,
    var recording: Recording? = null,
    var enableImageStream: Boolean = false,
    var photoSize: Size? = null,
    var previewSize: Size? = null,
    var aspectRatio: Int? = null,
    var flashMode: FlashMode = FlashMode.NONE,
    var previewStreamSink: EventChannel.EventSink? = null,
    val onStreamReady: (state: CameraXState) -> Unit,
) : EventChannel.StreamHandler {

    val maxZoomRatio: Double
        get() = previewCamera!!.cameraInfo.zoomState.value!!.maxZoomRatio.toDouble()


    val portrait: Boolean
        get() = previewCamera!!.cameraInfo.sensorRotationDegrees % 180 == 0

    fun executor(activity: Activity): Executor {
        return ContextCompat.getMainExecutor(activity)
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    fun updateLifecycle(activity: Activity) {
        // Preview
        if(aspectRatio != null) {
            preview = Preview.Builder()
                    .setTargetAspectRatio(aspectRatio!!)
                    .setCameraSelector(cameraSelector).build()
        } else {
            preview = Preview.Builder()
                    //.setTargetResolution(previewSize)
                    .setCameraSelector(cameraSelector).build()
        }

        preview!!.setSurfaceProvider(
            surfaceProvider(executor(activity))
        )

        if (currentCaptureMode == CaptureModes.PHOTO) {
            imageCapture = ImageCapture.Builder()
                .setCameraSelector(cameraSelector)
                .setTargetAspectRatio(aspectRatio ?: AspectRatio.RATIO_4_3)
                .apply {
                    photoSize?.let { setTargetResolution(it) }
                    setFlashMode(
                        when (flashMode) {
                            FlashMode.ALWAYS, FlashMode.ON -> ImageCapture.FLASH_MODE_ON
                            FlashMode.AUTO -> ImageCapture.FLASH_MODE_AUTO
                            else -> ImageCapture.FLASH_MODE_OFF
                        }
                    )
                }
                .build()
        } else {
            recorder = Recorder.Builder()
                .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                .build()
            videoCapture = VideoCapture.withOutput(recorder!!)
        }
        var imageAnalysis: ImageAnalysis? = null
        if (enableImageStream) {
            val width = 1024
            val analysisAspectRatio = when (aspectRatio) {
                AspectRatio.RATIO_4_3 -> 4f/3
                else -> 16f/9
            }
            val height =  width * (1/analysisAspectRatio)
            imageAnalysis = ImageAnalysis.Builder()
                .setTargetResolution(Size(width, height.toInt()))
                // Should backpressure be a parameter?
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
                .build()
            Log.d("CamerawesomePlugin", "image : $width / $height")
            imageAnalysis.setAnalyzer(executor(activity)) { imageProxy ->
                if (previewStreamSink != null) {
                    // Copying data between threads might be expensive
//                    Dispatchers.IO.run {
//                        val jpegImage = ImageUtil.yuvImageToJpegByteArray(
//                            imageProxy,
//                            Rect(0, 0, imageProxy.width, imageProxy.height),
//                            80
//                        )
//                        previewStreamSink!!.success(jpegImage)
//                        imageProxy.close()
//                    }
//                    previewStreamSink!!.success(imageProxy.)

                    val nv21Image = ImageUtil.yuv_420_888toNv21(imageProxy)
//                    val image = InputImage.fromMediaImage(imageProxy.image!!, imageProxy.imageInfo.rotationDegrees)
//                    val options = FaceDetectorOptions.Builder()
//                        .setContourMode(CONTOUR_MODE_ALL)
//                        .setClassificationMode(CLASSIFICATION_MODE_ALL)
//                        .build()
//                    val detector = FaceDetection.getClient(options)
//                    detector.process(image)
//                        .addOnSuccessListener { faces ->
//                            Log.d("CamerawesomePlugin", "faces detected: ${faces.size}")
//                        }
//                        .addOnFailureListener { e ->
//                            Log.e("CamerawesomePlugin", "failed detect faces", e)
//                        }
//                        .addOnCompleteListener {
//                            imageProxy.close()
//                        }

                    val planes = imageProxy.image!!.planes.map {
                        val byteArray = ByteArray(it.buffer.remaining())
                        it.buffer.get(byteArray, 0, byteArray.size)
                        mapOf(
                            "bytes" to byteArray,
                            "rowStride" to it.rowStride,
                            "pixelStride" to it.pixelStride
                        )
                    }
                    val yuvImageMap = mapOf(
                        "planes" to planes,
                        "height" to imageProxy.image!!.height,
                        "width" to imageProxy.image!!.width,
                        "format" to imageProxy.image!!.format,
                        "rotation" to imageProxy.imageInfo.rotationDegrees,
                        "nv21Image" to nv21Image
                    )
                    previewStreamSink!!.success(yuvImageMap)
                    imageProxy.close()
                } else {
                    imageProxy.close()
                }
            }
        }

        val useCases = mutableListOf(
            preview,
            if (currentCaptureMode == CaptureModes.PHOTO)
                imageCapture
            else videoCapture,
        ).apply { if (imageAnalysis != null) add(imageAnalysis) }
        cameraProvider.unbindAll()
        previewCamera = cameraProvider.bindToLifecycle(
            activity as LifecycleOwner,
            cameraSelector,
            *useCases.toTypedArray(),
        )
        previewCamera!!.cameraControl.enableTorch(flashMode == FlashMode.ALWAYS)
    }

    @SuppressLint("RestrictedApi")
    private fun surfaceProvider(executor: Executor): Preview.SurfaceProvider {
        //val metrics = DisplayMetrics().also { viewFinder.display.getRealMetrics(it) }
        //val screenSize = Size(metrics.widthPixels, metrics.heightPixels)
        //val screenAspectRatio = Rational(metrics.widthPixels, metrics.heightPixels)
        //val preview = Preview.Builder()
        //        .setTargetResolution(Size(640, 480))
        //        .setTargetAspectRatio(screenAspectRatio)
        //        .build()
        //val previewFit = AutoFitPreviewBuilder.build(preview., viewFinder)

        return Preview.SurfaceProvider { request: SurfaceRequest ->
            val resolution = request.resolution
            val texture = textureEntry.surfaceTexture()
            texture.setDefaultBufferSize(resolution.width, resolution.height)
            val surface = Surface(texture)
            request.provideSurface(surface, executor) { _: SurfaceRequest.Result? -> }
        }
    }

    fun setLinearZoom(zoom: Float) {
        previewCamera!!.cameraControl.setLinearZoom(zoom)
    }

    fun startFocusAndMetering(autoFocusAction: FocusMeteringAction) {
        previewCamera!!.cameraControl.startFocusAndMetering(autoFocusAction)
    }

    fun setCaptureMode(captureMode: CaptureModes) {
        currentCaptureMode = captureMode
        if (currentCaptureMode == CaptureModes.PHOTO) {
            // Release video related stuff
            videoCapture = null
            recording?.close()
            recording = null
            recorder = null

        } else {
            // Release photo related stuff
            imageCapture = null
        }
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    fun previewSizes(): List<Size> {
        val characteristics = CameraCharacteristicsCompat.toCameraCharacteristicsCompat(
            Camera2CameraInfo.extractCameraCharacteristics(previewCamera!!.cameraInfo)
        )
        return CamcorderProfileResolutionQuirk(characteristics).supportedResolutions
    }

    fun qualityAvailableSizes(): List<String> {
        val supportedQualities = QualitySelector.getSupportedQualities(previewCamera!!.cameraInfo)
        return supportedQualities.map {
            when (it) {
                Quality.UHD -> { "UHD" }
                Quality.HIGHEST -> { "HIGHEST" }
                Quality.FHD -> { "FHD" }
                Quality.HD -> { "HD" }
                Quality.LOWEST -> { "LOWEST" }
                Quality.SD -> { "SD" }
                else -> { "unknown" }
            }
        }
    }

    fun stop() {
        cameraProvider.unbindAll()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val previous = previewStreamSink;
        this.previewStreamSink = events
        if (previous == null && events != null) {
            onStreamReady(this)
        }
    }

    override fun onCancel(arguments: Any?) {
        this.previewStreamSink?.endOfStream()
        this.previewStreamSink = null
    }
}