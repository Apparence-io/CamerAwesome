package com.apparence.camerawesome.cameraX;

import static android.Manifest.permission.CAMERA;
import static android.Manifest.permission.WRITE_EXTERNAL_STORAGE;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.SurfaceTexture;
import android.util.Size;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageCapture;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import com.apparence.camerawesome.CameraPermissions;
import com.google.common.util.concurrent.ListenableFuture;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.view.TextureRegistry;

public class CameraAwesomeX implements Pigeon.CameraInterface, FlutterPlugin, ActivityAware {
    private FlutterPluginBinding binding;
    private TextureRegistry textureRegistry;
    private Activity activity;
    private ImageCapture imageCapture;
    private Camera previewCamera;
    private ProcessCameraProvider cameraProvider;
    private Executor executor;

    private static final String[] permissions = new String[]{CAMERA, WRITE_EXTERNAL_STORAGE};

    @Override
    public void setupCamera(Pigeon.Result<Void> result) {
        final ListenableFuture<ProcessCameraProvider> future = ProcessCameraProvider.getInstance(activity);
        this.executor = ContextCompat.getMainExecutor(activity);

        try {
            this.cameraProvider = future.get();
        } catch (ExecutionException | InterruptedException e) {
            e.printStackTrace();
            result.error(e);
        }
    }

    @Override
    public List<String> checkPermissions() {
        return Arrays.asList(new CameraPermissions().checkPermissions(activity));
    }

    @Override
    public List<String> requestPermissions() {
        new CameraPermissions().checkAndRequestPermissions(activity);
        return this.checkPermissions();
    }

    @Override
    public Pigeon.PreviewData getPreviewTextureId(Long id) {

        TextureRegistry.SurfaceTextureEntry textureEntry = this.textureRegistry.createSurfaceTexture();
        double textureId = textureEntry.id();

        // Preview
        Preview.SurfaceProvider surfaceProvider = (request) -> {
            Size resolution = request.getResolution();
            SurfaceTexture texture = textureEntry.surfaceTexture();
            texture.setDefaultBufferSize(resolution.getWidth(), resolution.getHeight());
            Surface surface = new Surface(texture);
            request.provideSurface(surface, executor, result -> {
            });
        };
        final Preview preview = new Preview.Builder().build();
        preview.setSurfaceProvider(surfaceProvider);

        this.imageCapture = new ImageCapture.Builder().build();

        // Bind to lifecycle.
        final LifecycleOwner owner = (LifecycleOwner) activity;
        final CameraSelector selector =
                id == 0 ? CameraSelector.DEFAULT_FRONT_CAMERA :
                        CameraSelector.DEFAULT_BACK_CAMERA;

        cameraProvider.unbindAll();
        this.previewCamera = cameraProvider.bindToLifecycle(owner, selector, preview, this.imageCapture);

        // TODO: seems there's not a better way to get the final resolution
        @SuppressLint("RestrictedApi")
        Size resolution = preview.getAttachedSurfaceResolution();
        boolean portrait = previewCamera.getCameraInfo().getSensorRotationDegrees() % 180 == 0;

        double width = (double) resolution.getWidth();
        double height = (double) resolution.getHeight();
        Map<String, Object> size = new HashMap<>();

        size.put(portrait ? "width" : "height", width);
        size.put(portrait ? "height" : "width", height);

        Pigeon.PreviewData answer = new Pigeon.PreviewData.Builder().build();

        answer.setTextureId(textureId);
        answer.setSize(Pigeon.PreviewSize.fromMap(size));

        return answer;
    }

    @Override
    public String takePicture() {
        return null;
    }

    @Override
    public String takeVideo() {
        return null;
    }

    //    FLUTTER ATTACHMENTS

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.binding = binding;
        this.textureRegistry = binding.getTextureRegistry();

        Pigeon.CameraInterface.setup(binding.getBinaryMessenger(), this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        this.binding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        this.activity = null;
    }
}
