package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.app.Activity
import android.hardware.camera2.CameraCharacteristics
import android.util.Log
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
import com.apparence.camerawesome.CamerawesomePlugin
import com.apparence.camerawesome.models.FlashMode
import com.apparence.camerawesome.sensors.SensorOrientation
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
    var mirrorFrontCamera: Boolean = false,
) : EventChannel.StreamHandler, SensorOrientation {

    var imageAnalysisBuilder: ImageAnalysisBuilder? = null
    var imageAnalysis: ImageAnalysis? = null

    val maxZoomRatio: Double
        get() = previewCamera!!.cameraInfo.zoomState.value!!.maxZoomRatio.toDouble()


    val portrait: Boolean
        get() = previewCamera!!.cameraInfo.sensorRotationDegrees % 180 == 0

    fun executor(activity: Activity): Executor {
        return ContextCompat.getMainExecutor(activity)
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    fun updateLifecycle(activity: Activity) {
        if (currentCaptureMode != CaptureModes.ANALYSIS_ONLY) {
            // Preview
            preview = if (aspectRatio != null) {
                Preview.Builder().setTargetAspectRatio(aspectRatio!!)
                    .setCameraSelector(cameraSelector).build()
            } else {
                Preview.Builder().setCameraSelector(cameraSelector).build()
            }

            preview!!.setSurfaceProvider(
                surfaceProvider(executor(activity))
            )
            if (currentCaptureMode == CaptureModes.PHOTO) {
                imageCapture = ImageCapture.Builder().setCameraSelector(cameraSelector)
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
                    }.build()
            } else if (currentCaptureMode == CaptureModes.VIDEO) {
                recorder =
                    Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                        .build()
                videoCapture = VideoCapture.withOutput(recorder!!)
            }
        }

        val addAnalysisUseCase = enableImageStream && imageAnalysisBuilder != null
        var useCases = mutableListOf(
            if (currentCaptureMode == CaptureModes.ANALYSIS_ONLY) null else preview,
            if (currentCaptureMode == CaptureModes.PHOTO) {
                imageCapture
            } else null,
            if (currentCaptureMode == CaptureModes.VIDEO) {
                videoCapture
            } else null,
        ).filterNotNull().toMutableList().apply {
            if (addAnalysisUseCase) {
                imageAnalysis = imageAnalysisBuilder!!.build()
                add(imageAnalysis!!)
            } else {
                imageAnalysis = null
            }
        }

        val cameraLevel = CameraCapabilities.getCameraLevel(
            cameraSelector, cameraProvider
        )
        cameraProvider.unbindAll()
        if (currentCaptureMode == CaptureModes.VIDEO && addAnalysisUseCase && cameraLevel < CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_3) {
            Log.w(
                CamerawesomePlugin.TAG,
                "Trying to bind too many use cases for this device (level $cameraLevel), ignoring image analysis"
            )
            useCases = useCases.filter { uc -> uc !is ImageAnalysis }.toMutableList()
        }

        previewCamera = cameraProvider.bindToLifecycle(
            activity as LifecycleOwner,
            cameraSelector,
            UseCaseGroup.Builder().apply {
                for (uc in useCases) addUseCase(uc)
            }
                // TODO Orientation might be wrong, to be verified
                .setViewPort(ViewPort.Builder(rational, Surface.ROTATION_0).build()).build(),
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
            request.provideSurface(surface, executor) { }
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
        when (currentCaptureMode) {
            CaptureModes.PHOTO -> {
                // Release video related stuff
                videoCapture = null
                recording?.close()
                recording = null
                recorder = null

            }

            CaptureModes.VIDEO -> {
                // Release photo related stuff
                imageCapture = null
            }

            else -> {
                // Preview and analysis only modes

                // Release video related stuff
                videoCapture = null
                recording?.close()
                recording = null
                recorder = null

                // Release photo related stuff
                imageCapture = null
            }
        }
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    fun previewSizes(): List<Size> {
        val characteristics = CameraCharacteristicsCompat.toCameraCharacteristicsCompat(
            Camera2CameraInfo.extractCameraCharacteristics(previewCamera!!.cameraInfo),
//            Camera2CameraInfo.from(previewCamera!!.cameraInfo).cameraId
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
        val previous = imageAnalysisBuilder?.previewStreamSink
        imageAnalysisBuilder?.previewStreamSink = events
        if (previous == null && events != null) {
            onStreamReady(this)
        }
    }

    override fun onCancel(arguments: Any?) {
        this.imageAnalysisBuilder?.previewStreamSink?.endOfStream()
        this.imageAnalysisBuilder?.previewStreamSink = null
    }

    override fun onOrientationChanged(orientation: Int) {
        imageAnalysis?.targetRotation = when (orientation) {
            in 225 until 315 -> {
                Surface.ROTATION_90
            }

            in 135 until 225 -> {
                Surface.ROTATION_180
            }

            in 45 until 135 -> {
                Surface.ROTATION_270
            }

            else -> {
                Surface.ROTATION_0
            }
        }
    }

    fun updateAspectRatio(newAspectRatio: String) {
        // In CameraX, aspect ratio is an Int. RATIO_4_3 = 0 (default), RATIO_16_9 = 1
        aspectRatio = if (newAspectRatio == "RATIO_16_9") 1 else 0
        rational = when (newAspectRatio) {
            "RATIO_16_9" -> Rational(9, 16)
            "RATIO_1_1" -> Rational(1, 1)
            else -> Rational(3, 4)
        }
    }


}