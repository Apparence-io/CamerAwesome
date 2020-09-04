package com.apparence.camerawesome.models;

import android.graphics.Rect;
import android.hardware.camera2.CameraCharacteristics;

public class CameraCharacteristicsModel {

    private float maxZoom;

    private Rect availablePreviewZone;

    private boolean hasAutoFocus;

    public CameraCharacteristicsModel(float maxZoom, Rect availablePreviewZone, boolean hasAutoFocus) {
        this.maxZoom = maxZoom;
        this.availablePreviewZone = availablePreviewZone;
        this.hasAutoFocus = hasAutoFocus;
    }

    public float getMaxZoom() {
        return maxZoom;
    }

    public boolean hasAutoFocus() { return hasAutoFocus; }

    public Rect getAvailablePreviewZone() {
        return availablePreviewZone;
    }

    public static class Builder {

        private float maxZoom;

        private Rect availablePreviewZone;

        private boolean hasAutoFocus;

        public Builder() {}

        public Builder withMaxZoom(float maxZoom) {
            this.maxZoom = maxZoom;
            return this;
        }

        public Builder withAvailablePreviewZone(Rect availablePreviewZone) {
            this.availablePreviewZone = availablePreviewZone;
            return this;
        }

        public Builder withAutoFocus(int[] modes) {
            if (modes == null || modes.length == 0
                    || (modes.length == 1 && modes[0] == CameraCharacteristics.CONTROL_AF_MODE_OFF)) {
                this.hasAutoFocus = false;
            } else {
                this.hasAutoFocus = true;
            }
            return this;
        }

        public CameraCharacteristicsModel build() {
            return new CameraCharacteristicsModel(
              this.maxZoom, this.availablePreviewZone, this.hasAutoFocus
            );
        }

    }
}
