package com.apparence.camerawesome.models;

import android.graphics.Rect;

public class CameraCharacteristicsModel {

    private float maxZoom;

    private Rect availablePreviewZone;

    public CameraCharacteristicsModel(float maxZoom, Rect availablePreviewZone) {
        this.maxZoom = maxZoom;
        this.availablePreviewZone = availablePreviewZone;
    }

    public float getMaxZoom() {
        return maxZoom;
    }

    public Rect getAvailablePreviewZone() {
        return availablePreviewZone;
    }

    public static class Builder {

        private float maxZoom;

        private Rect availablePreviewZone;

        public Builder() {}

        public Builder withMaxZoom(float maxZoom) {
            this.maxZoom = maxZoom;
            return this;
        }

        public Builder withAvailablePreviewZone(Rect availablePreviewZone) {
            this.availablePreviewZone = availablePreviewZone;
            return this;
        }

        public CameraCharacteristicsModel build() {
            return new CameraCharacteristicsModel(
              this.maxZoom, this.availablePreviewZone
            );
        }
    }
}
