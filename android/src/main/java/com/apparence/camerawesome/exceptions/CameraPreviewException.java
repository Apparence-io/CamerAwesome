package com.apparence.camerawesome.exceptions;

public class CameraPreviewException extends Exception {

    public enum Codes {
        EMPTY_SIZE
    }

    public CameraPreviewException() {
    }

    public CameraPreviewException(Codes code) {
        super(code.name());
    }

    public CameraPreviewException(Codes code, Throwable cause) {
        super(code.name(), cause);
    }

    public CameraPreviewException(Throwable cause) {
        super(cause);
    }


}
