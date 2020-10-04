package com.apparence.camerawesome.image;

import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.media.Image;
import android.media.ImageReader;
import android.os.Build;

import androidx.annotation.RequiresApi;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;

@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public
class YuvToJpgConverter implements ImgConverter{

    @Override
    public byte[] process(ImageReader reader) {
        final Image image = reader.acquireLatestImage();
        byte[] data = null;
        if (image != null) {
            Image.Plane[] planes = image.getPlanes();
            if (image.getFormat() == ImageFormat.JPEG) {
                ByteBuffer buffer = planes[0].getBuffer();
                data = new byte[buffer.capacity()];
                buffer.get(data);
                return data;
            } else if (image.getFormat() == ImageFormat.YUV_420_888) {
                data = NV21toJPEG(
                    YUV_420_888toI420SemiPlanar(
                            planes[0].getBuffer(),
                            planes[1].getBuffer(),
                            planes[2].getBuffer(),
                            image.getWidth(), image.getHeight(),
                            false),
                    image.getWidth(), image.getHeight(), 80);

            }
            image.close();
        }
        return data;
    }

    public byte[] NV21toJPEG(byte[] nv21, int width, int height, int quality) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        YuvImage yuv = new YuvImage(nv21, ImageFormat.NV21, width, height, null);
        yuv.compressToJpeg(new Rect(0, 0, width, height), quality, out);
        return out.toByteArray();
    }

    // nv12: true = NV12, false = NV21
    public byte[] YUV_420_888toNV(ByteBuffer yBuffer, ByteBuffer uBuffer, ByteBuffer vBuffer, boolean nv12) {
        byte[] nv;

        int ySize = yBuffer.remaining();
        int uSize = uBuffer.remaining();
        int vSize = vBuffer.remaining();

        nv = new byte[ySize + uSize + vSize];

        yBuffer.get(nv, 0, ySize);
        if (nv12) {//U and V are swapped
            vBuffer.get(nv, ySize, vSize);
            uBuffer.get(nv, ySize + vSize, uSize);
        } else {
            uBuffer.get(nv, ySize , uSize);
            vBuffer.get(nv, ySize + uSize, vSize);
        }
        return nv;
    }

    public byte[] YUV_420_888toI420SemiPlanar(ByteBuffer yBuffer, ByteBuffer uBuffer, ByteBuffer vBuffer,
                                                     int width, int height, boolean deInterleaveUV) {
        byte[] data = YUV_420_888toNV(yBuffer, uBuffer, vBuffer, deInterleaveUV);
        int size = width * height;
        if (deInterleaveUV) {
            byte[] buffer = new byte[3 * width * height / 2];

            // De-interleave U and V
            for (int i = 0; i < size / 4; i += 1) {
                buffer[i] = data[size + 2 * i + 1];
                buffer[size / 4 + i] = data[size + 2 * i];
            }
            System.arraycopy(buffer, 0, data, size, size / 2);
        } else {
            for (int i = size; i < data.length; i += 2) {
                byte b1 = data[i];
                data[i] = data[i + 1];
                data[i + 1] = b1;
            }
        }
        return data;
    }
}
