package com.apparence.camerawesome.cameraX

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.view.Surface
import androidx.camera.core.*
import androidx.camera.core.Preview.SurfaceProvider
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.apparence.camerawesome.CameraPermissions
import com.apparence.camerawesome.cameraX.Pigeon.CameraInterface
import com.apparence.camerawesome.cameraX.Pigeon.PreviewData
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.view.TextureRegistry
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executor

class CameraAwesomeX : CameraInterface, FlutterPlugin, ActivityAware {
    private var binding: FlutterPluginBinding? = null
    private var textureRegistry: TextureRegistry? = null
    private var activity: Activity? = null
    private var imageCapture: ImageCapture? = null
    private var previewCamera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var executor: Executor? = null
    override fun setupCamera(result: Pigeon.Result<Void>) {
        val future = ProcessCameraProvider.getInstance(
            activity!!
        )
        executor = ContextCompat.getMainExecutor(activity)
        try {
            cameraProvider = future.get()
        } catch (e: ExecutionException) {
            e.printStackTrace()
            result.error(e)
        } catch (e: InterruptedException) {
            e.printStackTrace()
            result.error(e)
        }
    }

    override fun checkPermissions(): List<String> {
        return listOf(*CameraPermissions().checkPermissions(activity))
    }

    override fun requestPermissions(): List<String> {
        CameraPermissions().checkAndRequestPermissions(activity)
        return checkPermissions()
    }

    override fun getPreviewTextureId(id: Long): PreviewData {
        val textureEntry = textureRegistry!!.createSurfaceTexture()
        val textureId = textureEntry.id().toDouble()

        // Preview
        val surfaceProvider = SurfaceProvider { request: SurfaceRequest ->
            val resolution = request.resolution
            val texture = textureEntry.surfaceTexture()
            texture.setDefaultBufferSize(resolution.width, resolution.height)
            val surface = Surface(texture)
            request.provideSurface(surface, executor!!) { result: SurfaceRequest.Result? -> }
        }
        val preview = Preview.Builder().build()
        preview.setSurfaceProvider(surfaceProvider)
        imageCapture = ImageCapture.Builder().build()

        // Bind to lifecycle.
        val owner = activity as LifecycleOwner?
        val selector =
            if (id == 0L) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
        cameraProvider!!.unbindAll()
        previewCamera = cameraProvider!!.bindToLifecycle(owner!!, selector, preview, imageCapture)

        // TODO: seems there's not a better way to get the final resolution
        @SuppressLint("RestrictedApi") val resolution = preview.attachedSurfaceResolution
        val portrait = previewCamera!!.cameraInfo.sensorRotationDegrees % 180 == 0
        val width = resolution!!.width.toDouble()
        val height = resolution.height.toDouble()
        val size: MutableMap<String, Any> = HashMap()
        size[if (portrait) "width" else "height"] = width
        size[if (portrait) "height" else "width"] = height
        val answer = PreviewData.Builder().build()
        answer.textureId = textureId
        answer.size = Pigeon.PreviewSize.fromMap(size)
        return answer
    }

    override fun takePicture(): String? {
        return null
    }

    override fun takeVideo(): String? {
        return null
    }

    //    FLUTTER ATTACHMENTS
    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        this.binding = binding
        textureRegistry = binding.textureRegistry
        CameraInterface.setup(binding.binaryMessenger, this)
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