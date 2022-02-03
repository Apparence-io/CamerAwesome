package com.apparence.camerawesome;

import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.util.concurrent.Executor;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.view.TextureRegistry;

public class CameraImplementation implements Pigeon.CameraInterface, FlutterPlugin, ActivityAware {
    private FlutterPluginBinding binding;
    private TextureRegistry texture;
    private Activity activity;

    @Override
    public String getPreviewTextureId() {

        final ListenableFuture<ProcessCameraProvider> future = ProcessCameraProvider.getInstance(activity);
        final Executor executor = ContextCompat.getMainExecutor(activity);
        future.addListener(() -> {
            try {
                this.cameraProvider = future.get();
                textureEntry = this.textureRegistry.createSurfaceTexture();
                long textureId = textureEntry.id();

                // Preview
                Preview.SurfaceProvider surfaceProvider = (request) -> {
                    Size resolution = request.getResolution();
                    SurfaceTexture texture = textureEntry.surfaceTexture();
                    texture.setDefaultBufferSize(resolution.getWidth(), resolution.getHeight());
                    Surface surface = new Surface(texture);
                    request.provideSurface(surface, executor, (res) -> {
                    });
                };
                final Preview preview = new Preview.Builder().build();
                preview.setSurfaceProvider(surfaceProvider);

                this.imageCapture = new ImageCapture.Builder().build();

                // Bind to lifecycle.
                final LifecycleOwner owner = (LifecycleOwner) activity;
                final CameraSelector selector =
                        (int) call.arguments == 0 ? CameraSelector.DEFAULT_FRONT_CAMERA :
                                CameraSelector.DEFAULT_BACK_CAMERA;
                cameraProvider.unbindAll();
                this.camera = cameraProvider.bindToLifecycle(owner, selector, preview, this.imageCapture);
//            this.camera.getCameraInfo().getTorchState().observe(owner, (state) ->
//                            // TorchState.OFF = 0; TorchState.ON = 1
//                    {
//                        Map event = new HashMap<>();
//                        event.put("name", "torchState");
//                        event.put("data", state);
//                        if (sink != null) {
//                            this.sink.success(event);
//                        }
//                    }
//            );
                // TODO: seems there's not a better way to get the final resolution
                @SuppressLint("RestrictedApi")
                Size resolution = preview.getAttachedSurfaceResolution();
                boolean portrait = camera.getCameraInfo().getSensorRotationDegrees() % 180 == 0;
                double width = (double) resolution.getWidth();
                double height = (double) resolution.getHeight();
                Map<String, Double> size = new HashMap<>();

                size.put(portrait ? "width" : "height", width);
                size.put(portrait ? "height" : "width", height);

                final Map<String, Object> answer = new HashMap<>();
                answer.put("textureId", textureId);
                answer.put("size", size);
                answer.put("torchable", true);

                result.success(answer);
            } catch (ExecutionException | InterruptedException e) {
                e.printStackTrace();
            }
        }, executor);
    }

    @Override
    public String takePicture() {
        return null;
    }

    @Override
    public String takeVideo() {
        return null;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.binding = binding;
        this.texture = binding.getTextureRegistry();

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
