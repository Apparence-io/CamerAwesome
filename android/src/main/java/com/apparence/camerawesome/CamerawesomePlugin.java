package com.apparence.camerawesome;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.hardware.camera2.CameraAccessException;
import android.os.Build;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.apparence.camerawesome.exceptions.CameraManagerException;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.TextureRegistry;

/**
 * CamerawesomePlugin
 * That Flutter plugin uses Camera2 to provide a better camera from android
 * This plugin recquire android Lolipop version (21) as a min version in your Android's gradle build
 * */
@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CamerawesomePlugin implements FlutterPlugin, MethodCallHandler, PluginRegistry.RequestPermissionsResultListener , ActivityAware {

  private static final String TAG = CamerawesomePlugin.class.getName();

  // application android context
  private Context applicationContext;

  // activity attached to plugin
  private Activity pluginActivity;

  // Flutter channel to send method results
  private MethodChannel channel;

  // Flutter texture registry
  private TextureRegistry textureRegistry;

  /// used by the [CameraPreview] to send images of camera with a stream into Flutter
  private EventChannel previewChannel;

  // handle setup of camera (get size, init...)
  private CameraSetup mCameraSetup;

  // handle image preview of camera
  private CameraPreview mCameraPreview;

  // handle start, stop...
  private CameraStateManager mCameraStateManager;

  // handle camera taking picture
  private CameraPicture mCameraPicture;

  // did user has accept all permissions
  private boolean permissionGranted = false;


  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    this.onAttachedToEngine(
            flutterPluginBinding.getApplicationContext(),
            flutterPluginBinding.getBinaryMessenger(),
            flutterPluginBinding.getTextureRegistry()
    );
  }

  // this is the old version of plugin used by flutter
  public static void registerWith(Registrar registrar) {
    final CamerawesomePlugin camerawesomePlugin = new CamerawesomePlugin();
    camerawesomePlugin.onAttachedToEngine(registrar.context(), registrar.messenger(), registrar.textures());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + Build.VERSION.RELEASE);
        break;
      case "checkPermissions":
        _handleCheckPermissions(call, result);
        break;
      case "requestPermissions":
        _handleRequestPermissions(call, result);
        break;
      case "init":
        _handleSetup(call, result);
        break;
      case "previewTexture":
        _handleGetTextures(call, result);
        break;
      case "availableSizes":
        _handleSizes(call, result);
        break;
      case "setPreviewSize":
        _handlePreviewSize(call, result);
        break;
      case "takePhoto":
        _handleTakePhoto(call, result);
        break;
      case "start":
        _handleStart(call, result);
        break;
      case "stop":
        _handleStop(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    previewChannel.setStreamHandler(null);
  }

  private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger, TextureRegistry textureRegistry) {
    this.applicationContext = applicationContext;
    channel = new MethodChannel(messenger, "camerawesome");
    previewChannel = new EventChannel(messenger, "camerawesome/live");
    channel.setMethodCallHandler(this);
    this.textureRegistry = textureRegistry;
  }

  // ----------------------------
  // METHODS
  // ----------------------------

  private void _handleCheckPermissions(MethodCall call, Result result) {
    Log.d(TAG, "_handleCheckPermissions: ");
    try {
      assert(pluginActivity !=null);
      String[] missingPermissions = CameraPermissions.checkPermissions(pluginActivity);
      if(missingPermissions.length == 0) {
        result.success(new ArrayList<>());
        this.permissionGranted = true;
      } else {
        result.success(Arrays.asList(missingPermissions));
        this.permissionGranted = false;
      }
    } catch (RuntimeException e) {
      result.error("FAILED_TO_CHECK_PERMISSIONS", "", e.getMessage());
    }

  }

  private void _handleRequestPermissions(MethodCall call, Result result) {
    CameraPermissions.checkAndRequestPermissions(pluginActivity);
  }

  private void _handleSetup(MethodCall call, Result result) {
    if(!this.permissionGranted) {
      result.error("MISSING_PERMISSION", "you got to accept all permissions", "");
      return;
    }
    if(call.argument("sensor") == null) {
      result.error("SENSOR_ERROR","a sensor FRONT or BACK must be provided", "");
      return;
    }
    String sensorArg = call.argument("sensor");
    CameraSensor sensor = sensorArg.equals("FRONT") ? CameraSensor.FRONT : CameraSensor.BACK;
    try {
      // init setup
      mCameraSetup = new CameraSetup(applicationContext, pluginActivity);
      mCameraSetup.chooseCamera(sensor);
      mCameraSetup.listenOrientation();
      // init preview
      mCameraPreview = new CameraPreview();
      mCameraPreview.setFlutterTexture(textureRegistry.createSurfaceTexture());
      // init state listener
      mCameraStateManager = new CameraStateManager(applicationContext, mCameraPreview);
      // init picture recorder
      mCameraPicture = new CameraPicture(mCameraStateManager.getBackgroundThread(), mCameraPreview.getCaptureSession());
      result.success(true);
    } catch (CameraAccessException e) {
      result.error("", e.getMessage(), e.getStackTrace());
    }
  }

  private void _handleGetTextures(MethodCall call, Result result) {
    if(mCameraPreview == null) {
      result.error("MUST_CALL_INIT", "", "");
    }
    result.success(mCameraPreview.getFlutterTexture());
  }

  private void _handleSizes(MethodCall call, Result result) {
    try {
      Size[] sizes = mCameraSetup.getOutputSizes();
      List<Object> sizesMap = new ArrayList<>();
      for(Size size : sizes) {
        Map<String, Object> resMap = new HashMap<>();
        resMap.put("width", size.getWidth());
        resMap.put("height", size.getHeight());
        sizesMap.add(resMap);
      }
      result.success(sizesMap);
    } catch (CameraAccessException e) {
      result.error(String.valueOf(e.getReason()), e.getMessage(), e);
    }
  }

  private void _handlePreviewSize(final MethodCall call, final Result result) {
    if(!call.hasArgument("width") || !call.hasArgument("height")) {
      result.error("NO_SIZE_SET", "width and height must be set", "");
      return;
    }
    int width = call.argument("width");
    int height = call.argument("height");
    mCameraPreview.setPreviewSize(width, height);
    result.success(null);
  }

  private void _handleStart(final MethodCall call, final Result result) {
    if(throwIfCameraNotInit(result)) {
      Log.e(TAG, "_handleStart: must be init before this");
      return;
    }
    try {
      mCameraStateManager.startCamera(mCameraSetup.getCameraId());
      result.success(true);
    } catch (CameraManagerException e) {
      result.error(e.getMessage(), "Error while starting camera", e.getStackTrace());
    }
  }

  private void _handleStop(MethodCall call, Result result) {
    if(throwIfCameraNotInit(result))
      return;
    mCameraStateManager.stopCamera();

  }

  private void _handleTakePhoto(final MethodCall call, final Result result) {
    if(!call.hasArgument("width") || !call.hasArgument("height")) {
      result.error("NO_SIZE_SET", "width and height must be set", "");
      return;
    }
    if(!call.hasArgument("path")) {
      result.error("PATH_NOT_SET", "a file path must be set", "");
      return;
    }
    @SuppressWarnings("ConstantConditions")
    int width = call.argument("width");
    @SuppressWarnings("ConstantConditions")
    int height = call.argument("height");
    Size size = new Size(width, height);
    String path = call.argument("path");
    try {
      mCameraPicture.takePicture(
              mCameraStateManager.getCameraDevice(),
              path,
              mCameraSetup.getCurrentOrientation(),
              size,
              createTakePhotoResultListener(result)
      );
    } catch (CameraAccessException e) {
      result.error(e.getMessage(), "cannot open camera", "");
    }
  }

  private CameraPicture.OnImageResult createTakePhotoResultListener(final Result result) {
    return new CameraPicture.OnImageResult() {
      @Override
      public void onSuccess() {
        result.success(null);
      }
      @Override
      public void onFailure(String error) {
        result.error(error, "", "");
      }
    };
  }

  /**
   * Returns true if camera has not been init and should not go next
   * @param result boolean
   * @return true if has throw
   */
  private boolean throwIfCameraNotInit(Result result) {
    if(mCameraSetup == null) {
      result.error("CAMERA_MUST_BE_INIT", "init must be call before start", "");
      return true;
    }
    return false;
  }

  // ----------------------------
  // REQUEST PERMISSION
  // ----------------------------

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    permissionGranted = true;
    for(int i=0; i < permissions.length; i++) {
      if(grantResults[i] != PackageManager.PERMISSION_GRANTED) {
        permissionGranted = false;
        break;
      }
    }
    return permissionGranted;
  }

  // ----------------------------
  // ActivityAware
  // ----------------------------

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    Log.d(TAG, "onAttachedToActivity: ");
    this.pluginActivity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    Log.d(TAG, "onDetachedFromActivityForConfigChanges: ");
    this.pluginActivity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    Log.d(TAG, "onReattachedToActivityForConfigChanges: ");
    this.pluginActivity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this);
  }

  @Override
  public void onDetachedFromActivity() {
    Log.d(TAG, "onDetachedFromActivity: ");
    this.pluginActivity = null;

  }
}
