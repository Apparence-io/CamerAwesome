package com.apparence.camerawesome.cameraX

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.location.Location
import android.util.Log
import android.util.Size
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.VideoRecordEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.util.Consumer
import com.apparence.camerawesome.*
import com.apparence.camerawesome.models.FlashMode
import com.apparence.camerawesome.sensors.CameraSensor
import com.apparence.camerawesome.sensors.SensorOrientationListener
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.view.TextureRegistry
import java.io.File
import java.util.concurrent.TimeUnit
import kotlin.math.roundToInt

enum class CaptureModes {
    PHOTO,
    VIDEO,
}

class CameraAwesomeX : CameraInterface, FlutterPlugin, ActivityAware {
    private var binding: FlutterPluginBinding? = null
    private var textureRegistry: TextureRegistry? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var activity: Activity? = null
    private lateinit var imageStreamChannel: EventChannel
    private lateinit var orientationStreamChannel: EventChannel
    private var orientationStreamListener: OrientationStreamListener? = null
    private val sensorOrientationListener: SensorOrientationListener = SensorOrientationListener()

    private lateinit var cameraState: CameraXState
    private val cameraPermissions = CameraPermissions()
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var exifPreferences: ExifPreferences
    private var cancellationTokenSource = CancellationTokenSource()


    @SuppressLint("RestrictedApi")
    override fun setupCamera(
        sensor: String,
        captureMode: String,
        enableImageStream: Boolean,
        exifPreferences: ExifPreferences,
        callback: (Boolean) -> Unit,
    ) {
        this.exifPreferences = ExifPreferences(saveGPSLocation = exifPreferences.saveGPSLocation)
        val future = ProcessCameraProvider.getInstance(
            activity!!
        )
        val cameraProvider = future.get()
        orientationStreamListener = OrientationStreamListener(activity!!, sensorOrientationListener)
        textureEntry = textureRegistry!!.createSurfaceTexture()

        val cameraSelector =
            if (CameraSensor.valueOf(sensor) == CameraSensor.BACK) CameraSelector.DEFAULT_BACK_CAMERA else CameraSelector.DEFAULT_FRONT_CAMERA

        cameraState = CameraXState(
            textureRegistry!!,
            textureEntry!!,
            cameraProvider = cameraProvider,
            cameraSelector = cameraSelector,
            currentCaptureMode = CaptureModes.valueOf(captureMode),
            enableImageStream = enableImageStream,
            onStreamReady = { state -> state.updateLifecycle(activity!!) }
        )
        if (enableImageStream) {
            imageStreamChannel.setStreamHandler(cameraState)
        }

        cameraState.updateLifecycle(activity!!)
        callback(true)
    }

    override fun setupImageAnalysisStream(format: String, width: Long) {
        cameraState.apply {
            try {
                this.imageAnalysisBuilder = ImageAnalysisBuilder.configure(
                    aspectRatio ?: AspectRatio.RATIO_4_3,
                    OutputImageFormat.valueOf(format.uppercase()),
                    executor(activity!!),
                    width
                )
                updateLifecycle(activity!!)
            } catch (e: Exception) {
                Log.e(CamerawesomePlugin.TAG, "error while enable image analysis", e)
            }
        }

    }

    override fun setExifPreferences(exifPreferences: ExifPreferences) {
        this.exifPreferences = exifPreferences
    }

    override fun checkPermissions(): List<String> {
        return listOf(*cameraPermissions.checkPermissions(activity))
    }

    override fun requestPermissions(): List<String> {
        cameraPermissions.checkAndRequestPermissions(activity)
        return checkPermissions()
    }

    private fun getOrientedSize(width: Int, height: Int): Size {
        val portrait = cameraState.portrait
        return Size(
            if (portrait) width else height,
            if (portrait) height else width,
        )
    }

    override fun getPreviewTextureId(): Double {
        return textureEntry!!.id().toDouble()
    }

    /***
     * [fusedLocationClient.getCurrentLocation] takes time, we might want to use
     * [fusedLocationClient.lastLocation] instead to go faster
     */
    private fun retrieveLocation(callback: (Location?) -> Unit) {
        if (exifPreferences.saveGPSLocation &&
            ActivityCompat.checkSelfPermission(
                activity!!,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            fusedLocationClient.getCurrentLocation(
                Priority.PRIORITY_HIGH_ACCURACY,
                cancellationTokenSource.token
            ).addOnCompleteListener {
                if (it.isSuccessful) {
                    callback(it.result)
                } else {
                    if (it.exception != null) {
                        Log.e(
                            CamerawesomePlugin.TAG,
                            "Error finding location",
                            it.exception
                        )
                    }
                    callback(null)
                }
            }
        } else {
            callback(null)
        }
    }

    override fun takePhoto(path: String, callback: (Boolean) -> Unit) {
        val imageFile = File(path)
        imageFile.parentFile?.mkdirs()

        takePhotoWith(imageFile, callback)

    }

    @SuppressLint("RestrictedApi")
    private fun takePhotoWith(
        imageFile: File,
        callback: (Boolean) -> Unit
    ) {
        val outputFileOptions = ImageCapture.OutputFileOptions
            .Builder(imageFile)
            .setMetadata(ImageCapture.Metadata())
            .build()

        cameraState.imageCapture!!.takePicture(
            outputFileOptions,
            ContextCompat.getMainExecutor(activity!!),
            object : ImageCapture.OnImageSavedCallback {

                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    Log.d(
                        CamerawesomePlugin.TAG,
                        "Success capturing picture ${outputFileResults.savedUri}"
                    )
                    if (exifPreferences.saveGPSLocation) {
                        retrieveLocation {
                            Log.d("Location retrieved", "${it?.latitude}x${it?.longitude}")
                            outputFileOptions.metadata.location = it
                        }
                    }
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
                        cameraState.apply {
                            recording?.close()
                            recording = null
                        }
                        Log.d(
                            CamerawesomePlugin.TAG,
                            "Video capture ends with error: ${event.error}"
                        )

                    }
                }
            }
        }
        cameraState.recording = cameraState.videoCapture!!.output.prepareRecording(
            activity!!,
            FileOutputOptions.Builder(File(path)).build()
        ).apply { if (cameraState.enableAudioRecording) withAudioEnabled() }
            .start(cameraState.executor(activity!!), recordingListener)
    }

    override fun stopRecordingVideo() {
        cameraState.recording?.stop()
    }

    override fun pauseVideoRecording() {
        cameraState.recording?.pause()
    }

    override fun resumeVideoRecording() {
        cameraState.recording?.resume()
    }


    override fun start(): Boolean {
        // Already started on setUp
        return true
    }

    override fun stop(): Boolean {
        cameraState.stop()
        return true
    }

    override fun setFlashMode(mode: String) {
        val flashMode = FlashMode.valueOf(mode)
        cameraState.apply {
            this.flashMode = flashMode
            updateLifecycle(activity!!)
        }
    }

    override fun handleAutoFocus() {
        focus()
    }

    override fun setZoom(zoom: Double) {
        cameraState.setLinearZoom(zoom.toFloat())
    }

    @SuppressLint("RestrictedApi")
    override fun setSensor(sensor: String) {
        val cameraSelector =
            if (CameraSensor.valueOf(sensor) == CameraSensor.BACK)
                CameraSelector.DEFAULT_BACK_CAMERA
            else
                CameraSelector.DEFAULT_FRONT_CAMERA
        cameraState.apply {
            this.cameraSelector = cameraSelector
            updateLifecycle(activity!!)
        }
    }

    override fun setCorrection(brightness: Double) {
        // TODO brightness calculation might not be the same as before CameraX
        val range = cameraState.previewCamera?.cameraInfo?.exposureState?.exposureCompensationRange
        if (range != null) {
            val actualBrightnessValue = brightness * (range.upper - range.lower) + range.lower
            cameraState.previewCamera?.cameraControl
                ?.setExposureCompensationIndex(actualBrightnessValue.roundToInt())
        }
    }

    override fun getMaxZoom(): Double {
        return cameraState.maxZoomRatio
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
            cameraState.startFocusAndMetering(autoFocusAction)
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
            cameraState.previewCamera!!.cameraControl.startFocusAndMetering(
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
        cameraState.apply {
            setCaptureMode(CaptureModes.valueOf(mode))
            updateLifecycle(activity!!)
        }
    }

    /// Changing the recording audio mode can't be changed once a recording has starded
    override fun setRecordingAudioMode(enableAudio: Boolean) {
        cameraState.apply {
            enableAudioRecording = enableAudio
            // No need to update lifecycle, it will be applied on next recording
        }
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    override fun availableSizes(): List<PreviewSize> {
        return cameraState.previewSizes().map {
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
        val res = cameraState.preview!!.resolutionInfo?.resolution
        return if (res != null) {
            PreviewSize(res.width.toDouble(), res.height.toDouble())
        } else {
            PreviewSize(0.0, 0.0)
        }
    }

    @SuppressLint("RestrictedApi")
    override fun setPhotoSize(size: PreviewSize) {
        cameraState.apply {
            photoSize = getOrientedSize(size.width.toInt(), size.height.toInt())
            updateLifecycle(activity!!)
        }
    }

    @SuppressLint("RestrictedApi")
    override fun setPreviewSize(size: PreviewSize) {
        cameraState.apply {
            previewSize = getOrientedSize(size.width.toInt(), size.height.toInt())
            updateLifecycle(activity!!)
        }
    }

    override fun setAspectRatio(value: String) {
        cameraState.apply {
            aspectRatio = when (value) {
                AspectRatio.RATIO_16_9.toString() -> {
                    AspectRatio.RATIO_16_9
                }
                AspectRatio.RATIO_4_3.toString() -> {
                    AspectRatio.RATIO_4_3
                }
                else -> {
                    null
                }
            }
            updateLifecycle(activity!!)
        }
    }


    //    FLUTTER ATTACHMENTS
    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        this.binding = binding
        textureRegistry = binding.textureRegistry
        CameraInterface.setUp(binding.binaryMessenger, this)
        orientationStreamChannel = EventChannel(binding.binaryMessenger, "camerawesome/orientation")
        orientationStreamChannel.setStreamHandler(sensorOrientationListener)
        imageStreamChannel = EventChannel(binding.binaryMessenger, "camerawesome/images")
        EventChannel(binding.binaryMessenger, "camerawesome/permissions").setStreamHandler(
            cameraPermissions
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(cameraPermissions)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(cameraPermissions)
    }

    override fun onDetachedFromActivity() {
        activity = null
        cancellationTokenSource.cancel()
        cameraPermissions.onCancel(null)
    }
}