package com.apparence.camerawesome.sensors;

import io.flutter.plugin.common.EventChannel;

public class SensorOrientationListener implements EventChannel.StreamHandler, SensorOrientation {

    EventChannel.EventSink events;

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.events = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.events.endOfStream();
        this.events = null;
    }

    @Override
    public void notify(int orientation) {
        if (this.events == null) {
            return;
        }
        switch (orientation) {
            case 0:
                events.success("PORTRAIT_UP");
                break;
            case 90:
                events.success("LANDSCAPE_LEFT");
                break;
            case 180:
                events.success("PORTRAIT_DOWN");
                break;
            case 270:
                events.success("LANDSCAPE_RIGHT");
                break;
        }
    }
}
