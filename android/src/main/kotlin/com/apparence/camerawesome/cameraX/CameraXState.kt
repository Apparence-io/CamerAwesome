package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.app.Activity
import android.graphics.Rect
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
import com.apparence.camerawesome.CamerawesomePlugin
import com.apparence.camerawesome.models.FlashMode
import io.flutter.plugin.common.EventChannel
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.Dispatchers
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
            Log.d(CamerawesomePlugin.TAG, "...enabling image analysis stream")
            imageAnalysis = ImageAnalysis.Builder()
                // TODO What should the targetResolutionSize be?
                .setTargetResolution(Size(640, 480))
                // TODO Should backpressure be a parameter?
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
                .build()
            imageAnalysis.setAnalyzer(executor(activity)) { imageProxy ->
                Log.d(CamerawesomePlugin.TAG, "...image stream image found")
                if (previewStreamSink != null) { //FIXME this is null
                    Log.d(CamerawesomePlugin.TAG, "...pushing image")
                    // TODO Not sure of the benefits of running the conversion in the background
                    // Copying data between threads might be expensive
                    Dispatchers.IO.run {
                        val jpegImage = ImageUtil.yuvImageToJpegByteArray(
                            imageProxy,
                            Rect(0, 0, imageProxy.width, imageProxy.height),
                            75
                        )
                        previewStreamSink!!.success(jpegImage)
                        imageProxy.close()
                    }
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
        val next = events;

        this.previewStreamSink = events
        if (previous == null && next != null) {
            onStreamReady(this)
        }
    }

    override fun onCancel(arguments: Any?) {
        this.previewStreamSink?.endOfStream()
        this.previewStreamSink = null
    }
}