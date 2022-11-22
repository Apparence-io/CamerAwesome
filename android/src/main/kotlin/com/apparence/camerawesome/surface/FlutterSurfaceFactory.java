package com.apparence.camerawesome.surface;

import android.graphics.SurfaceTexture;
import android.os.Build;
import android.util.Size;
import android.view.Surface;

import androidx.annotation.RequiresApi;

import io.flutter.view.TextureRegistry;

public class FlutterSurfaceFactory implements SurfaceFactory {

    private TextureRegistry registry;

    private TextureRegistry.SurfaceTextureEntry flutterTexture;


    public FlutterSurfaceFactory(TextureRegistry registry) {
        this.registry = registry;
    }

    @Override
    public Surface build(Size size) {
        flutterTexture = registry.createSurfaceTexture();
        SurfaceTexture surfaceTexture = flutterTexture.surfaceTexture();
        surfaceTexture.setDefaultBufferSize(size.getWidth(), size.getHeight());
        return new Surface(surfaceTexture);
    }

    @Override
    public long getSurfaceId() {
        if(flutterTexture == null) {
            throw new RuntimeException("flutterTexture is null");
        }
        return flutterTexture.id();
    }
}
