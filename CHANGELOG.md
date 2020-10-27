## 0.1.1+1
- [android] fix release onOpenListener after emit result to Flutter platform
## 0.1.1
- prevent starting camera when already open on Flutter side
- stability between rebuilds improved on Flutter side
- [android] check size is correctly set before starting camera
- CameraPreview try 3 times to start if camera is locked (each try are 1s ellapsed)
- Fix android zoom when taking picture
## 0.1.0
- image stream available to use MLkit or other image live processing (Only android)
## 0.0.2+3
- fix switch camera on Android with new update (now correctly switch ImageReader and cameraCharacteristics when switch sensor).
## 0.0.2+1
- comment com.google.gms.google-services from example build.gradle.
This is aimed only to start our e2e tests on testlabs. Put your own google-services.json if you want to start them there.
## 0.0.2
- updated readme
## 0.0.1
- first version. See readme for complete features list
