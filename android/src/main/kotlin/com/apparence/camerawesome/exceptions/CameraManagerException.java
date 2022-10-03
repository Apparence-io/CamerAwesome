package com.apparence.camerawesome.exceptions;

public class CameraManagerException extends Exception {

    public enum Codes {
        MISSING_PERMISSION,
        INTERRUPTED,
        CANNOT_OPEN_CAMERA,
        LOCKED
    }

    public CameraManagerException() {
    }

    public CameraManagerException(Codes code) {
        super(code.name());
    }

    public CameraManagerException(Codes code, Throwable cause) {
        super(code.name(), cause);
    }

    public CameraManagerException(Throwable cause) {
        super(cause);
    }


}
