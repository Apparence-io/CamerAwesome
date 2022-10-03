package com.apparence.camerawesome.image;

import android.media.Image;
import android.media.ImageReader;

public interface ImgConverter {

    byte[] process(ImageReader imageReader);
}
