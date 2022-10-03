package com.apparence.camerawesome.cameraX

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.util.Log
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
import androidx.core.util.Consumer
import androidx.lifecycle.LifecycleOwner
import com.apparence.camerawesome.*
import com.apparence.camerawesome.models.FlashMode
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.view.TextureRegistry
import java.io.File
import java.util.concurrent.TimeUnit

enum class CaptureModes {
    PHOTO,
    VIDEO,
}

class CameraAwesomeX : CameraInterface, FlutterPlugin, ActivityAware {
    private var binding: FlutterPluginBinding? = null
    private var textureRegistry: TextureRegistry? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var activity: Activity? = null

    private lateinit var cameraState: CameraXState

    private var imageCapture: ImageCapture? = null
    private var recorder: Recorder? = null
    private var videoCapture: VideoCapture<Recorder>? = null

    private var preview: Preview? = null
    private var previewCamera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private lateinit var currentCaptureMode: CaptureModes

    private var enableAudioRecording: Boolean = true
    var recording: Recording? = null


    val executor get() = ContextCompat.getMainExecutor(activity)

    @SuppressLint("RestrictedApi")
    override fun setupCamera(sensor: String, captureMode: String, enableImageStream: Boolean) {
        val future = ProcessCameraProvider.getInstance(
            activity!!
        )
        cameraProvider = future.get()

        currentCaptureMode = CaptureModes.valueOf(captureMode)

        textureEntry = textureRegistry!!.createSurfaceTexture()

        val cameraSelector =
            if (CameraSensor.valueOf(sensor) == CameraSensor.BACK) CameraSelector.DEFAULT_BACK_CAMERA else CameraSelector.DEFAULT_FRONT_CAMERA

//        cameraState = CameraXState(
//            textureRegistry!!,
//            textureEntry!!,
//            imageCapture,
//            cameraSelector,
//            recorder,
//            videoCapture,
//            preview,
//            previewCamera,
//            cameraProvider,
//            currentCaptureMode,
//            enableImageStream = false,
//        )
//        cameraState.updateLifecycle(activity!!)

        // Preview
        preview = Preview.Builder().setCameraSelector(cameraSelector).build()
        preview!!.setSurfaceProvider(surfaceProvider())

        if (currentCaptureMode == CaptureModes.PHOTO) {
            imageCapture = ImageCapture.Builder().setCameraSelector(cameraSelector).build()
        } else {
            recorder = Recorder.Builder()
                .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                .build()
            videoCapture = VideoCapture.withOutput(recorder!!)
        }
        if (enableImageStream && false) {
            // TODO implement imageanalysis usecase
            val imageAnalysis = ImageAnalysis.Builder()
                // enable the following line if RGBA output is needed.
                // .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                // TODO What should the targetResolutionSize be?
                .setTargetResolution(Size(1280, 720))
                // TODO Should backpressure be a parameter?
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
            imageAnalysis.setAnalyzer(executor) { imageProxy ->
                // Somehow pass the imageProxy to Flutter
                val rotationDegrees = imageProxy.imageInfo.rotationDegrees

                // after done, release the ImageProxy object
                imageProxy.close()
            }
        }

        cameraProvider!!.unbindAll()
        previewCamera = cameraProvider!!.bindToLifecycle(
            activity as LifecycleOwner,
            if (CameraSensor.valueOf(sensor) == CameraSensor.BACK) CameraSelector.DEFAULT_BACK_CAMERA else CameraSelector.DEFAULT_FRONT_CAMERA,
            preview,
            if (currentCaptureMode == CaptureModes.PHOTO)
                imageCapture
            else videoCapture,
//            imageAnalysis,
        )
    }

    override fun checkPermissions(): List<String> {
        return listOf(*CameraPermissions().checkPermissions(activity))
    }

    override fun requestPermissions(): List<String> {
        CameraPermissions().checkAndRequestPermissions(activity)
        return checkPermissions()
    }

    private fun surfaceProvider(): Preview.SurfaceProvider {
        return Preview.SurfaceProvider { request: SurfaceRequest ->
            val resolution = request.resolution
            val texture = textureEntry!!.surfaceTexture()
            texture.setDefaultBufferSize(resolution.width, resolution.height)
            val surface = Surface(texture)
            request.provideSurface(surface, executor!!) { result: SurfaceRequest.Result? -> }
        }
    }

    private fun getOrientedSize(width: Int, height: Int): Size {
        val portrait = previewCamera!!.cameraInfo.sensorRotationDegrees % 180 == 0
        return Size(
            if (portrait) width else height,
            if (portrait) height else width,
        )
    }

    override fun getPreviewTextureId(): Double {
        return textureEntry!!.id().toDouble()
    }


    override fun takePhoto(path: String, callback: (Boolean) -> Unit) {
        val imageFile = File(path)
        imageFile.parentFile?.mkdirs()
        val outputFileOptions = ImageCapture.OutputFileOptions
            .Builder(imageFile)
//            .setMetadata()
            .build()

        imageCapture!!.takePicture(
            outputFileOptions,
            ContextCompat.getMainExecutor(activity),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    Log.d(
                        CamerawesomePlugin.TAG,
                        "Success capturing picture ${outputFileResults.savedUri}"
                    )
                    callback(true)
                }

                override fun onError(exception: ImageCaptureException) {
                    Log.e(CamerawesomePlugin.TAG, "Error capturing picture", exception)
                    callback(false)
                }
            })
    }

    override fun recordVideo(path: String) {
        val recordingListener = Consumer<VideoRecordEvent> { event ->
            when (event) {
                is VideoRecordEvent.Start -> {
                    Log.d(CamerawesomePlugin.TAG, "Capture Started")
                }
                is VideoRecordEvent.Finalize -> {
                    if (!event.hasError()) {
                        Log.d(
                            CamerawesomePlugin.TAG,
                            "Video capture succeeded: ${event.outputResults.outputUri}"
                        )
                    } else {
                        // update app state when the capture failed.
                        recording?.close()
                        recording = null
                        Log.d(
                            CamerawesomePlugin.TAG,
                            "Video capture ends with error: ${event.error}"
                        )
                    }
                }
            }
        }
        recording = videoCapture!!.output
            .prepareRecording(activity!!, FileOutputOptions.Builder(File(path)).build())
            .apply { if (enableAudioRecording) withAudioEnabled() }
            .start(executor, recordingListener)
    }

    override fun stopRecordingVideo() {
        recording?.stop()
    }

    override fun pauseVideoRecording() {
        recording?.pause()
    }

    override fun resumeVideoRecording() {
        recording?.resume()
    }


    override fun start(): Boolean {
        // Already started on setUp
        return true
    }

    override fun stop(): Boolean {
        cameraProvider!!.unbindAll()
        return true
    }

    override fun setFlashMode(mode: String) {
        val flashMode = FlashMode.valueOf(mode)
        previewCamera!!.cameraControl.enableTorch(flashMode == FlashMode.ALWAYS)
        imageCapture!!.flashMode =
            when (flashMode) {
                FlashMode.ALWAYS, FlashMode.ON -> ImageCapture.FLASH_MODE_ON
                FlashMode.AUTO -> ImageCapture.FLASH_MODE_AUTO
                else -> ImageCapture.FLASH_MODE_OFF
            }
    }

    override fun handleAutoFocus() {
        focus()
    }

    override fun setZoom(zoom: Double) {
        previewCamera!!.cameraControl.setLinearZoom(zoom.toFloat())
    }

    @SuppressLint("RestrictedApi")
    override fun setSensor(sensor: String) {
        val cameraSensor = CameraSensor.valueOf(sensor)
        cameraProvider!!.unbindAll()

        val cameraSelector =
            if (cameraSensor == CameraSensor.BACK) CameraSelector.DEFAULT_BACK_CAMERA else CameraSelector.DEFAULT_FRONT_CAMERA
        preview = Preview.Builder().setCameraSelector(cameraSelector).build()
        preview!!.setSurfaceProvider(surfaceProvider())
        imageCapture = ImageCapture.Builder().setCameraSelector(cameraSelector).build()

        cameraProvider!!.bindToLifecycle(
            activity as LifecycleOwner,
            cameraSelector,
            preview,
            imageCapture,
        )
    }

    override fun setCorrection(brightness: Double) {
        // TODO find how to translate brightness to exposure value below
//        previewCamera!!.cameraControl.setExposureCompensationIndex(brightness)
        TODO("Not yet implemented")
    }

    override fun getMaxZoom(): Double {
        // TODO Null might happen?
        return previewCamera!!.cameraInfo.zoomState.value!!.maxZoomRatio.toDouble()
    }

    override fun focus() {
        val autoFocusPoint = SurfaceOrientedMeteringPointFactory(1f, 1f)
            .createPoint(.5f, .5f)
        try {
            val autoFocusAction = FocusMeteringAction.Builder(
                autoFocusPoint,
                FocusMeteringAction.FLAG_AF
            ).apply {
                //start auto-focusing after 2 seconds
                setAutoCancelDuration(2, TimeUnit.SECONDS)
            }.build()
            previewCamera!!.cameraControl.startFocusAndMetering(autoFocusAction)
        } catch (e: CameraInfoUnavailableException) {
            throw e
        }
    }

    // TODO Use this in CamerAwesome lib
    fun focusOnPoint(size: PreviewSize, x: Double, y: Double) {
        val factory: MeteringPointFactory = SurfaceOrientedMeteringPointFactory(
            size.width.toFloat(), size.height.toFloat(),
        )
        val autoFocusPoint = factory.createPoint(x.toFloat(), y.toFloat())
        try {
            previewCamera!!.cameraControl.startFocusAndMetering(
                FocusMeteringAction.Builder(
                    autoFocusPoint,
                    FocusMeteringAction.FLAG_AF
                ).apply {
                    //focus only when the user tap the preview
                    disableAutoCancel()
                }.build()
            )
        } catch (e: CameraInfoUnavailableException) {
            throw e
        }
    }

    @SuppressLint("RestrictedApi")
    override fun setCaptureMode(mode: String) {
        currentCaptureMode = CaptureModes.valueOf(mode)

        if (currentCaptureMode == CaptureModes.PHOTO) {
            imageCapture =
                ImageCapture.Builder().setCameraSelector(previewCamera!!.cameraInfo.cameraSelector)
                    .build()
        } else {
            val recorder = Recorder.Builder()
                .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                .build()
            videoCapture = VideoCapture.withOutput(recorder)
        }

        cameraProvider!!.unbindAll()
        previewCamera = cameraProvider!!.bindToLifecycle(
            activity as LifecycleOwner,
            previewCamera!!.cameraInfo.cameraSelector,
            preview,
            if (currentCaptureMode == CaptureModes.PHOTO)
                imageCapture
            else videoCapture
        )
    }

    /// Changing the recording audio mode can't be changed once a recording has starded
    override fun setRecordingAudioMode(enableAudio: Boolean) {
        enableAudioRecording = enableAudio
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    override fun availableSizes(): List<PreviewSize> {
        val characteristics = CameraCharacteristicsCompat.toCameraCharacteristicsCompat(
            Camera2CameraInfo.extractCameraCharacteristics(previewCamera!!.cameraInfo)
        )
        val previewSizes = CamcorderProfileResolutionQuirk(characteristics).supportedResolutions
        // Don't change these sizes as they will be used later and converted
        return previewSizes.map {
            PreviewSize(
                width = it.width.toDouble(),
                height = it.height.toDouble()
            )
        }
    }

    override fun refresh() {
//        TODO Nothing to do?
    }

    @SuppressLint("RestrictedApi")
    override fun getEffectivPreviewSize(): PreviewSize {
        val res = preview?.resolutionInfo?.resolution
        return if (res != null) {
            PreviewSize(res.width.toDouble(), res.height.toDouble())
        } else {
            PreviewSize(0.0, 0.0)
        }
    }

    @SuppressLint("RestrictedApi")
    override fun setPhotoSize(size: PreviewSize) {
        imageCapture = ImageCapture.Builder()
            .setCameraSelector(previewCamera!!.cameraInfo.cameraSelector)
            .setTargetResolution(getOrientedSize(size.width.toInt(), size.height.toInt()))
            .build()
        cameraProvider?.unbindAll()
        cameraProvider!!.bindToLifecycle(
            activity as LifecycleOwner,
            previewCamera!!.cameraInfo.cameraSelector,
            preview,
            imageCapture,
        )
    }

    @SuppressLint("RestrictedApi")
    override fun setPreviewSize(size: PreviewSize) {
        preview =
            Preview.Builder()
                .setCameraSelector(previewCamera!!.cameraInfo.cameraSelector)
                .setTargetResolution(getOrientedSize(size.width.toInt(), size.height.toInt()))
                .build()
        preview!!.setSurfaceProvider(surfaceProvider())

        cameraProvider?.unbindAll()
        cameraProvider!!.bindToLifecycle(
            activity as LifecycleOwner,
            previewCamera!!.cameraInfo.cameraSelector,
            preview,
            imageCapture,
        )
    }

    @SuppressLint("RestrictedApi")
    fun bindToLifecycle() {
        if (currentCaptureMode == CaptureModes.PHOTO) {
            imageCapture =
                ImageCapture.Builder()
                    .setCameraSelector(previewCamera!!.cameraInfo.cameraSelector)
                    .build()
        } else {
            val recorder = Recorder.Builder()
                .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                .build()
            videoCapture = VideoCapture.withOutput(recorder)
        }

        cameraProvider!!.unbindAll()
        previewCamera = cameraProvider!!.bindToLifecycle(
            activity as LifecycleOwner,
            previewCamera!!.cameraInfo.cameraSelector,
            preview,
            if (currentCaptureMode == CaptureModes.PHOTO)
                imageCapture
            else videoCapture
        )
    }

    //    FLUTTER ATTACHMENTS
    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        this.binding = binding
        textureRegistry = binding.textureRegistry
        CameraInterface.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    companion object {
        private val permissions =
            arrayOf(Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE)
    }
}