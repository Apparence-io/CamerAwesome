package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.app.Activity
import android.util.Log
import android.util.Rational
import android.util.Size
import android.view.Surface
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.*
import androidx.camera.core.concurrent.ConcurrentCamera
import androidx.camera.core.concurrent.ConcurrentCameraConfig
import androidx.camera.core.concurrent.SingleCameraConfig
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.apparence.camerawesome.models.FlashMode
import com.apparence.camerawesome.sensors.SensorOrientation
import io.flutter.plugin.common.EventChannel
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executor

/// Hold the settings of the camera and use cases in this class and
/// call updateLifecycle() to refresh the state
data class CameraXState(
    private var cameraProvider: ProcessCameraProvider,
    val textureEntries: Map<String, TextureRegistry.SurfaceTextureEntry>,
//    var cameraSelector: CameraSelector,
    var sensors: List<PigeonSensor>,
    var imageCapture: ImageCapture? = null,
    var videoCapture: VideoCapture<Recorder>? = null,
    private var recorder: Recorder? = null,
    var previews: MutableList<Preview>? = null,
    var concurrentCamera: ConcurrentCamera? = null,
    var previewCamera: Camera? = null,
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
        previews = mutableListOf()
        if (isMultiCamSupported() && sensors.size > 1) {
            val useCaseGroupBuilder = UseCaseGroup.Builder()
            var isFirst = true
            val cameraSelectors = mutableListOf<CameraSelector>()
            for ((index, sensor) in sensors.withIndex()) {
//                val cameraSelector = CameraSelector.Builder()
//                    .requireLensFacing(if (sensor.position == PigeonSensorPosition.FRONT) CameraSelector.LENS_FACING_FRONT else CameraSelector.LENS_FACING_BACK)
//                    .addCameraFilter(CameraFilter { cameraInfos ->
//                        val list = mutableListOf<CameraInfo>()
//                        cameraInfos.forEach { cameraInfo ->
//                            Camera2CameraInfo.from(cameraInfo).let {
//                                if (it.getPigeonPosition() == sensor.position && (it.getSensorType() == sensor.type || it.getSensorType() == PigeonSensorType.UNKNOWN)) {
//                                    list.add(cameraInfo)
//                                }
//                            }
//                        }
//                        if (list.isEmpty()) {
//                            // If no camera found, only filter based on the sensor position and ignore sensor type
//                            cameraInfos.forEach { cameraInfo ->
//                                Camera2CameraInfo.from(cameraInfo).let {
//                                    if (it.getPigeonPosition() == sensor.position) {
//                                        list.add(cameraInfo)
//                                    }
//                                }
//                            }
//                        }
//                        return@CameraFilter list
//                    })
//                    .build()
                val cameraSelector =
                    if (isFirst) CameraSelector.DEFAULT_BACK_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
                cameraSelectors.add(cameraSelector)


                val preview = if (aspectRatio != null) {
                    Preview.Builder().setTargetAspectRatio(aspectRatio!!)
                        .setCameraSelector(cameraSelector).build()
                } else {
                    Preview.Builder().setCameraSelector(cameraSelector).build()
                }
                preview.setSurfaceProvider(
                    surfaceProvider(executor(activity), sensor.deviceId ?: "$index")
                )
                useCaseGroupBuilder.addUseCase(preview)
                previews!!.add(preview)

                if (currentCaptureMode == CaptureModes.PHOTO) {
                    imageCapture = ImageCapture.Builder().setCameraSelector(cameraSelector)
//                .setJpegQuality(100)
                        .apply {
                            //photoSize?.let { setTargetResolution(it) }
                            if (rational.denominator != rational.numerator) {
                                setTargetAspectRatio(aspectRatio ?: AspectRatio.RATIO_4_3)
                            }

                            setFlashMode(
                                if (isFirst) when (flashMode) {
                                    FlashMode.ALWAYS, FlashMode.ON -> ImageCapture.FLASH_MODE_ON
                                    FlashMode.AUTO -> ImageCapture.FLASH_MODE_AUTO
                                    else -> ImageCapture.FLASH_MODE_OFF
                                }
                                else ImageCapture.FLASH_MODE_OFF
                            )
                        }.build()
                } else {
                    recorder =
                        Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                            .build()
                    videoCapture = VideoCapture.withOutput(recorder!!)
                }
                if (isFirst && enableImageStream && imageAnalysisBuilder != null) {
                    imageAnalysis = imageAnalysisBuilder!!.build()
                    useCaseGroupBuilder.addUseCase(imageAnalysis!!)
                } else {
                    imageAnalysis = null
                }
                // TODO Add other use cases
//                if (isFirst) {
//                    for (uc in listOfNotNull(imageCapture, videoCapture, imageAnalysis)) {
//                        useCaseGroupBuilder.addUseCase(uc)
//                    }
//                }
                isFirst = false
            }
            useCaseGroupBuilder.setViewPort(ViewPort.Builder(rational, Surface.ROTATION_0).build())
            val useCaseGroup = useCaseGroupBuilder.build()

            cameraProvider.unbindAll()

            previewCamera = null
            val selectors = cameraSelectors.map {
                SingleCameraConfig.Builder().setLifecycleOwner(activity as LifecycleOwner)
                    .setCameraSelector(it).setUseCaseGroup(useCaseGroup).build()
            }
            concurrentCamera = cameraProvider.bindToLifecycle(
                ConcurrentCameraConfig.Builder().setCameraConfigs(selectors).build()
            )
            concurrentCamera!!.cameras.first().cameraControl.enableTorch(flashMode == FlashMode.ALWAYS)
        } else {
            // Handle single camera
            val cameraSelector =
                if (sensors.first().position == PigeonSensorPosition.FRONT) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
            // Preview
            previews!!.add(
                if (aspectRatio != null) {
                    Preview.Builder().setTargetAspectRatio(aspectRatio!!)
                        .setCameraSelector(cameraSelector).build()
                } else {
                    Preview.Builder().setCameraSelector(cameraSelector).build()
                }
            )

            previews!!.first().setSurfaceProvider(
                surfaceProvider(executor(activity), sensors.first().deviceId ?: "0")
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
            } else {
                recorder =
                    Recorder.Builder().setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                        .build()
                videoCapture = VideoCapture.withOutput(recorder!!)
            }

            val useCases = mutableListOf(
                previews!!.first(),
                if (currentCaptureMode == CaptureModes.PHOTO) {
                    imageCapture
                } else {
                    videoCapture
                },
            ).apply {
                if (enableImageStream && imageAnalysisBuilder != null) {
                    imageAnalysis = imageAnalysisBuilder!!.build()
                    add(imageAnalysis!!)
                } else {
                    imageAnalysis = null
                }
            }

            cameraProvider.unbindAll()

            val useCaseGroup = UseCaseGroup.Builder().apply {
                for (uc in useCases.filterNotNull()) addUseCase(uc)
            }
                // TODO Orientation might be wrong, to be verified
                .setViewPort(ViewPort.Builder(rational, Surface.ROTATION_0).build()).build()

            concurrentCamera = null
            previewCamera = cameraProvider.bindToLifecycle(
                activity as LifecycleOwner,
                cameraSelector,
                useCaseGroup,
            )
            previewCamera!!.cameraControl.enableTorch(flashMode == FlashMode.ALWAYS)
        }
    }

    @SuppressLint("RestrictedApi")
    private fun surfaceProvider(executor: Executor, cameraId: String): Preview.SurfaceProvider {
        Log.d("SurfaceProviderCamX", "Creating surface provider for $cameraId")
        return Preview.SurfaceProvider { request: SurfaceRequest ->
            val resolution = request.resolution
            val texture = textureEntries[cameraId]!!.surfaceTexture()
            texture.setDefaultBufferSize(resolution.width, resolution.height)
            val surface = Surface(texture)
            request.provideSurface(surface, executor) {
                Log.d("CameraX", "Surface request result: ${it.resultCode}")
                surface.release()
            }
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
//        val characteristics = CameraCharacteristicsCompat.toCameraCharacteristicsCompat(
//            Camera2CameraInfo.extractCameraCharacteristics(previewCamera!!.cameraInfo)
//        )
//        return CamcorderProfileResolutionQuirk(characteristics).supportedResolutions
        TODO("Not implemented anymore")
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

    @SuppressLint("RestrictedApi")
    @ExperimentalCamera2Interop
    fun isMultiCamSupported(): Boolean {
        val concurrentInfos = cameraProvider.availableConcurrentCameraInfos
        return concurrentInfos.isNotEmpty()
    }
}