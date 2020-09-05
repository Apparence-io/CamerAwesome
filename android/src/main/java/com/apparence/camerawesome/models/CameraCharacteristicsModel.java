package com.apparence.camerawesome.models;

import android.graphics.Rect;
import android.hardware.camera2.CameraCharacteristics;

public class CameraCharacteristicsModel {

    private float maxZoom;

    private Rect availablePreviewZone;

    private boolean hasAutoFocus;

    private Boolean flashAvailable;

    public CameraCharacteristicsModel(float maxZoom, Rect availablePreviewZone, boolean hasAutoFocus, boolean hasFlash) {
        this.maxZoom = maxZoom;
        this.availablePreviewZone = availablePreviewZone;
        this.hasAutoFocus = hasAutoFocus;
        this.flashAvailable = hasFlash;
    }

    public float getMaxZoom() {
        return maxZoom;
    }

    public Boolean hasFlashAvailable() { return flashAvailable; }

    public boolean hasAutoFocus() { return hasAutoFocus; }

    public Rect getAvailablePreviewZone() {
        return availablePreviewZone;
    }

    public static class Builder {

        private float maxZoom;

        private Rect availablePreviewZone;

        private boolean hasAutoFocus;

        private Boolean flashAvailable;

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

        public Builder withFlash(Boolean flashAvailable) {
            this.flashAvailable = flashAvailable;
            return this;
        }

        public CameraCharacteristicsModel build() {
            return new CameraCharacteristicsModel(
              this.maxZoom, this.availablePreviewZone, this.hasAutoFocus, this.flashAvailable
            );
        }

    }
}
