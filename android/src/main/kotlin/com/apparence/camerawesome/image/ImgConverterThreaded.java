package com.apparence.camerawesome.image;

import android.media.ImageReader;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;


public class ImgConverterThreaded {

    private static HandlerThread handlerThread = new HandlerThread("ImgConverterThreaded");

    private ImgConverter converter;

    public ImgConverterThreaded(ImgConverter converter) {
        if(handlerThread != null) {
            handlerThread.quit();
            handlerThread = new HandlerThread("ImgConverterThreaded");
        }
        this.converter = converter;
        handlerThread.start();
    }

    public void process(final ImageReader imageReader, final Consumer consumer) {
        Looper looper = handlerThread.getLooper();
        if(looper == null) {
            return;
        }
        Handler handler = new Handler(looper);
        handler.post(new Runnable() {
            @Override
            public void run() {
                consumer.process(converter.process(imageReader));
            }
        });
    }

    public void dispose() {
        handlerThread.quitSafely();
    }

    public interface Consumer {
        void process(byte[] result);
    }
}
