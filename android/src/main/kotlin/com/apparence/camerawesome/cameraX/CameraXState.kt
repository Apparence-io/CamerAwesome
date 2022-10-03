package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.app.Activity
import android.util.Size
import android.view.Surface
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.camera.video.VideoCapture
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executor

data class CameraXState(
    val textureRegistry: TextureRegistry,
    val textureEntry: TextureRegistry.SurfaceTextureEntry,
    var imageCapture: ImageCapture?,
    val cameraSelector: CameraSelector,
    private var recorder: Recorder? = null,
    private var videoCapture: VideoCapture<Recorder>? = null,

    private var preview: Preview? = null,
    private var previewCamera: Camera? = null,
    private var cameraProvider: ProcessCameraProvider? = null,
    private var currentCaptureMode: CaptureModes,

    private var enableAudioRecording: Boolean = true,
    var recording: Recording? = null,

    val enableImageStream: Boolean = false
) {

    private fun executor(activity: Activity): Executor {
        return ContextCompat.getMainExecutor(activity)
    }

    @SuppressLint("RestrictedApi")
    fun updateLifecycle(activity: Activity) {
        // Preview
        preview = Preview.Builder().setCameraSelector(cameraSelector).build()
        preview!!.setSurfaceProvider(
            surfaceProvider(executor(activity))
        )

        if (currentCaptureMode == CaptureModes.PHOTO) {
            imageCapture = ImageCapture.Builder().setCameraSelector(cameraSelector).build()
        } else {
            recorder = Recorder.Builder()
                .setQualitySelector(QualitySelector.from(Quality.HIGHEST))
                .build()
            videoCapture = VideoCapture.withOutput(recorder!!)
        }
        if (enableImageStream) {
            // TODO implement imageanalysis usecase
            val imageAnalysis = ImageAnalysis.Builder()
                // enable the following line if RGBA output is needed.
                // .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                // TODO What should the targetResolutionSize be?
                .setTargetResolution(Size(1280, 720))
                // TODO Should backpressure be a parameter?
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
            imageAnalysis.setAnalyzer(executor(activity)) { imageProxy ->
                // Somehow pass the imageProxy to Flutter
                val rotationDegrees = imageProxy.imageInfo.rotationDegrees

                // after done, release the ImageProxy object
                imageProxy.close()
            }
        }

        cameraProvider!!.unbindAll()
        previewCamera = cameraProvider!!.bindToLifecycle(
            activity as LifecycleOwner,
            cameraSelector,
            preview,
            if (currentCaptureMode == CaptureModes.PHOTO)
                imageCapture
            else videoCapture,
//            imageAnalysis,
        )
    }

    private fun surfaceProvider(executor: Executor): Preview.SurfaceProvider {
        return Preview.SurfaceProvider { request: SurfaceRequest ->
            val resolution = request.resolution
            val texture = textureEntry.surfaceTexture()
            texture.setDefaultBufferSize(resolution.width, resolution.height)
            val surface = Surface(texture)
            request.provideSurface(surface, executor) { result: SurfaceRequest.Result? -> }
        }
    }
}