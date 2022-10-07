package com.apparence.camerawesome.surface;

import android.util.Size;
import android.view.Surface;

public interface SurfaceFactory {

    /**
     * Creates a surfaceTexture used to create a Surface
     * Surface are used to show camera preview
     * @param previewSize
     * @return
     */
    Surface build(Size previewSize);

    long getSurfaceId();
}
