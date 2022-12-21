package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.app.Activity
import android.util.Rational
import android.util.Size
import android.view.Surface
import androidx.camera.camera2.internal.compat.CameraCharacteristicsCompat
import androidx.camera.camera2.internal.compat.quirk.CamcorderProfileResolutionQuirk
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.*
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
    // Rational is used only in ratio 1:1
    var rational: Rational = Rational(3, 4),
    var flashMode: FlashMode = FlashMode.NONE,
    val onStreamReady: (state: CameraXState) -> Unit,
) : EventChannel.StreamHandler {

    var imageAnalysisBuilder: ImageAnalysisBuilder? = null

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
        preview = if (aspectRatio != null) {
            Preview.Builder()
                .setTargetAspectRatio(aspectRatio!!)
                .setCameraSelector(cameraSelector).build()
        } else {
            Preview.Builder()
                .setCameraSelector(cameraSelector).build()
        }

        preview!!.setSurfaceProvider(
            surfaceProvider(executor(activity))
        )
        if (currentCaptureMode == CaptureModes.PHOTO) {
            imageCapture = ImageCapture.Builder()
                .setCameraSelector(cameraSelector)
//                .setJpegQuality(100)
                .apply {
                    //photoSize?.let { setTargetResolution(it) }
                    if (rational.denominator != rational.numerator) {
                        setTargetAspectRatio(aspectRatio ?: AspectRatio.RATIO_4_3)
                    }
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

        val useCases = mutableListOf(
            preview,
            if (currentCaptureMode == CaptureModes.PHOTO) {
                imageCapture
            } else {
                videoCapture
            },
        ).apply {
            if (imageAnalysisBuilder != null) {
                add(imageAnalysisBuilder!!.build())
            }
        }

        cameraProvider.unbindAll()
        previewCamera = if (rational.denominator == rational.numerator)
            cameraProvider.bindToLifecycle(
                activity as LifecycleOwner,
                cameraSelector,
                UseCaseGroup.Builder()
                    .apply {
                        for (uc in useCases.filterNotNull())
                            addUseCase(uc)
                    }
                    // We don't care about the rotation since rational is only used on 1:1 ratio
                    .setViewPort(ViewPort.Builder(rational, Surface.ROTATION_0).build())
                    .build()
            )
        else
            cameraProvider.bindToLifecycle(
                activity as LifecycleOwner,
                cameraSelector,
                *useCases.toTypedArray()
            )

        previewCamera!!.cameraControl.enableTorch(flashMode == FlashMode.ALWAYS)
    }

    @SuppressLint("RestrictedApi")
    private fun surfaceProvider(executor: Executor): Preview.SurfaceProvider {
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
                Quality.UHD -> {
                    "UHD"
                }
                Quality.HIGHEST -> {
                    "HIGHEST"
                }
                Quality.FHD -> {
                    "FHD"
                }
                Quality.HD -> {
                    "HD"
                }
                Quality.LOWEST -> {
                    "LOWEST"
                }
                Quality.SD -> {
                    "SD"
                }
                else -> {
                    "unknown"
                }
            }
        }
    }

    fun stop() {
        cameraProvider.unbindAll()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val previous = imageAnalysisBuilder?.previewStreamSink;
        imageAnalysisBuilder?.previewStreamSink = events
        if (previous == null && events != null) {
            onStreamReady(this)
        }
    }

    override fun onCancel(arguments: Any?) {
        this.imageAnalysisBuilder?.previewStreamSink?.endOfStream()
        this.imageAnalysisBuilder?.previewStreamSink = null
    }
}