package com.apparence.camerawesome.sensors;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

import io.flutter.plugin.common.EventChannel;

import static android.content.Context.SENSOR_SERVICE;

public class BasicLuminosityNotifier implements LuminosityNotifier, EventChannel.StreamHandler {

    SensorManager mSensorManager;
    Sensor mLightSensor;

    EventChannel.EventSink notifyChannel;

    @Override
    public void init(Context context) {
        if(mSensorManager != null && mLightSensor != null)
            return;
        mSensorManager = (SensorManager) context.getSystemService(SENSOR_SERVICE);
        mLightSensor = mSensorManager.getDefaultSensor(Sensor.TYPE_LIGHT);

        mSensorManager.registerListener(lightListener, mLightSensor, SensorManager.SENSOR_DELAY_UI);
    }

    final SensorEventListener lightListener = new SensorEventListener() {
        @Override
        public void onSensorChanged(SensorEvent event) {
            if(notifyChannel != null && event != null && event.values != null &&  event.values.length > 0) {
                notifyChannel.success(event.values[0]);
            }
        }

        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) { }
    };

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.notifyChannel = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.notifyChannel.endOfStream();
        this.notifyChannel = null;
    }
}
