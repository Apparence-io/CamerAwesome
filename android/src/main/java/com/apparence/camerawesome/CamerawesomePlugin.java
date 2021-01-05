package com.apparence.camerawesome;

import android.app.Activity;
import android.content.Context;
import android.hardware.camera2.CameraAccessException;
import android.os.Build;
import android.os.Handler;
import android.util.Log;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.apparence.camerawesome.CameraSettingsManager.CameraSettingsHandler;
import com.apparence.camerawesome.exceptions.CameraManagerException;
import com.apparence.camerawesome.models.FlashMode;
import com.apparence.camerawesome.sensors.BasicLuminosityNotifier;
import com.apparence.camerawesome.sensors.LuminosityNotifier;
import com.apparence.camerawesome.sensors.SensorOrientationListener;
import com.apparence.camerawesome.surface.FlutterSurfaceFactory;

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
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.TextureRegistry;

/**
 * CamerawesomePlugin
 * That Flutter plugin uses Camera2 to provide a better camera from android
 * This plugin recquire android Lolipop version (21) as a min version in your Android's gradle build
 * */
@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class CamerawesomePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

  private static final String TAG = CamerawesomePlugin.class.getName();

  // application android context
  private Context applicationContext;

  // activity attached to plugin
  private Activity pluginActivity;

  // manage current required permissions
  private CameraPermissions cameraPermissions;

  // Flutter channel to send method results
  private MethodChannel channel;

  // Flutter event channel to listen orientation changes from sensor
  private EventChannel sensorOrientationChannel;

  // Flutter permission event channel to listen on result
  private EventChannel permissionsResultChannel;

  // Flutter images stream event channel
  private EventChannel imageStreamChannel;

  // Fluter luminosity level event channel
  private EventChannel luminosityStreamChannel;

  // Flutter texture registry
  private TextureRegistry textureRegistry;

  // handle setup of camera (get size, init...)
  private CameraSetup mCameraSetup;

  // handle camera settings
  private CameraSettingsManager mSettingsManager;

  // handle luminosity change notifying
  private LuminosityNotifier mLuminosityNotifier;

  // handle image preview of camera
  private CameraPreview mCameraPreview;

  // handle start, stop...
  private CameraStateManager mCameraStateManager;

  // handle camera taking picture
  private CameraPicture mCameraPicture;

  // handle the session between CameraPicture and CameraSession
  private CameraSession mCameraSession;

  // listen sensor orientation
  private SensorOrientationListener mSensorOrientation = new SensorOrientationListener();

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
    camerawesomePlugin.setPluginActivity(registrar.activity());
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
      case "setSensor":
        _handleSwitchSensor(call, result);
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
      case "getEffectivPreviewSize":
        _handleGetEffectivPreviewSize(call, result);
        break;
      case "setPhotoSize":
        _handlePhotoSize(call, result);
        break;
      case "takePhoto":
        _handleTakePhoto(call, result);
        break;
      case "setFlashMode":
        _handleFlashMode(call, result);
        break;
      case "handleAutoFocus":
        _handleAutoFocus(call, result);
        break;
      case "start":
        _handleStart(call, result);
        break;
      case "getMaxZoom":
        _handleGetMaxZoom(call, result);
        break;
      case "setZoom":
        _handleZoom(call, result);
        break;
      case "setCorrection":
        _handleManualBrightness(call, result);
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
  }

  private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger, TextureRegistry textureRegistry) {
    this.applicationContext = applicationContext;
    cameraPermissions = new CameraPermissions();
    mLuminosityNotifier = new BasicLuminosityNotifier();
    channel = new MethodChannel(messenger, "camerawesome");
    sensorOrientationChannel = new EventChannel(messenger, "camerawesome/orientation");
    permissionsResultChannel = new EventChannel(messenger, "camerawesome/permissions");
    imageStreamChannel = new EventChannel(messenger, "camerawesome/images");
    luminosityStreamChannel = new EventChannel(messenger, "camerawesome/luminosity");
    channel.setMethodCallHandler(this);
    sensorOrientationChannel.setStreamHandler(mSensorOrientation);
    permissionsResultChannel.setStreamHandler(cameraPermissions);
    luminosityStreamChannel.setStreamHandler((EventChannel.StreamHandler) mLuminosityNotifier);
    this.textureRegistry = textureRegistry;
  }

  // ----------------------------
  // METHODS
  // ----------------------------

  private void _handleCheckPermissions(MethodCall call, Result result) {
    Log.d(TAG, "_handleCheckPermissions: ");
    try {
      assert(pluginActivity !=null);
      String[] missingPermissions = cameraPermissions.checkPermissions(pluginActivity);
      if(missingPermissions.length == 0) {
        result.success(new ArrayList<>());
      } else {
        result.success(Arrays.asList(missingPermissions));
      }
    } catch (RuntimeException e) {
      result.error("FAILED_TO_CHECK_PERMISSIONS", "", e.getMessage());
    }

  }

  private void _handleRequestPermissions(MethodCall call, Result result) {
    cameraPermissions.checkAndRequestPermissions(pluginActivity);
  }

  private void _handleSetup(MethodCall call, Result result) {
    if(!this.cameraPermissions.hasPermissionGranted()) {
      result.error("MISSING_PERMISSION", "you got to accept all permissions before setup", "");
      return;
    }
    if(call.argument("sensor") == null) {
      result.error("SENSOR_ERROR","a sensor FRONT or BACK must be provided", "");
      return;
    }
    boolean streamImages = false;
    if(call.argument("streamImages") != null) {
      streamImages = call.argument("streamImages");
    }
    String sensorArg = call.argument("sensor");
    CameraSensor sensor = sensorArg.equals("FRONT") ? CameraSensor.FRONT : CameraSensor.BACK;
    try {
      // init setup
      mCameraSetup = new CameraSetup(applicationContext, pluginActivity, mSensorOrientation);
      mCameraSetup.chooseCamera(sensor);
      mCameraSetup.listenOrientation();
      // init luminosity notifier
      mLuminosityNotifier.init(applicationContext);
      // init camera session builder
      mCameraSession = new CameraSession();
      // init preview with camera caracteristics we needs
      mCameraPreview = new CameraPreview(
              mCameraSession,
              mCameraSetup.getCharacteristicsModel(),
              new FlutterSurfaceFactory(textureRegistry),
              new Handler(pluginActivity.getMainLooper()),
              streamImages);
      imageStreamChannel.setStreamHandler(mCameraPreview);
      // init picture recorder
      mCameraPicture = new CameraPicture(mCameraSession, mCameraSetup.getCharacteristicsModel());
      // init settings manager
      List<CameraSettingsHandler> handlers = new ArrayList<CameraSettingsHandler>();
      handlers.add(mCameraPreview);
      handlers.add(mCameraPicture);
      mSettingsManager = new CameraSettingsManager(mCameraSetup.getCharacteristicsModel(), handlers);
      // init state listener
      mCameraStateManager = new CameraStateManager(applicationContext, mCameraPreview, mCameraPicture, mCameraSession);
      // set camera sessions listeners
      List<CameraSession.OnCaptureSession> onCaptureSessionListners = new ArrayList<CameraSession.OnCaptureSession>();
      onCaptureSessionListners.add(mCameraPreview);
      onCaptureSessionListners.add(mCameraPicture);
      mCameraSession.setOnCaptureSessionListenerList(onCaptureSessionListners);
      result.success(true);
    } catch (CameraAccessException e) {
      result.error("", e.getMessage(), e.getStackTrace());
    }
  }

  private void _handleSwitchSensor(MethodCall call, Result result) {
    if(throwIfCameraNotInit(result)) {
      return;
    }
    CameraSensor sensor = CameraSensor.valueOf((String) call.argument("sensor"));
    Log.d(TAG, "_handleSwitchSensor: " + sensor.name() + " => " +  ((String) call.argument("sensor")));
    try {
      mCameraSetup.chooseCamera(sensor);
      mCameraStateManager.switchCamera(mCameraSetup.getCameraId(), mCameraSetup.getCharacteristicsModel());
      result.success(null);
    } catch (CameraAccessException | CameraManagerException e) {
      result.error("SWITCH_CAMERA_SENSOR_ERROR", e.getMessage(), e.getStackTrace());
    }
  }

  private void _handleGetTextures(MethodCall call, Result result) {
    if(mCameraPreview == null) {
      result.error("MUST_CALL_INIT", "", "");
      return;
    }
    try {
        long id = mCameraPreview.getFlutterTexture();
        result.success(id);
    } catch (RuntimeException e) {
        result.error("TEXTURE_NOT_FOUND", "cannot find texture", "");
    }
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

  private void _handleGetEffectivPreviewSize(MethodCall call, Result result) {
      if(throwIfCameraNotInit(result))
          return;
      Size size = mCameraPreview.getPreviewSize();
      Map<String, Object> resMap = new HashMap<>();
      resMap.put("width", size.getWidth());
      resMap.put("height", size.getHeight());
      result.success(resMap);
  }

  private void _handlePhotoSize(MethodCall call, Result result) {
    if(!call.hasArgument("width") || !call.hasArgument("height")) {
      result.error("NO_SIZE_SET", "width and height must be set", "");
      return;
    }
    int width = call.argument("width");
    int height = call.argument("height");
    mCameraPicture.setSize(width, height);
    mCameraSession.refresh();
    result.success(null);
  }


  private void _handleStart(final MethodCall call, final Result result) {
    if(throwIfCameraNotInit(result)) {
      Log.e(TAG, "_handleStart: must be init before this");
      return;
    }
    if(mCameraPicture.getSize() == null) {
      result.error("NO_PICTURE_SIZE", "","");
      return;
    }
    try {
      mCameraStateManager.setmOnCameraStateListener(new CameraStateManager.OnCameraState() {
        @Override
        public void onOpened() {
          result.success(true);
          mCameraStateManager.setmOnCameraStateListener(null);
        }
        @Override
        public void onOpenError(String reason) {
          result.error(reason, "","");
        }
      });
      mCameraStateManager.startCamera(mCameraSetup.getCameraId());
    } catch (CameraManagerException e) {
      result.error(e.getMessage(), "Error while starting camera", e.getStackTrace());
    }
  }

  private void _handleManualBrightness(MethodCall call, Result result) {
    if(throwIfCameraNotInit(result))
      return;
    double brightness = call.argument("brightness");
    try {
      mSettingsManager.setManualBrightness(brightness);
      result.success(null);
    } catch (IllegalArgumentException e) {
      result.error("ArgumentError", "ArgumentError", "Value for brightness compensation must be between 0 and -1");
    }
  }

  private void _handleStop(MethodCall call, Result result) {
    if(throwIfCameraNotInit(result))
      return;
    mCameraStateManager.stopCamera();
    result.success(true);
  }

  private void _handleTakePhoto(final MethodCall call, final Result result) {
    if(!call.hasArgument("path")) {
      result.error("PATH_NOT_SET", "a file path must be set", "");
      return;
    }
    String path = call.argument("path");
    try {
      mCameraPicture.takePicture(
              mCameraStateManager.getCameraDevice(),
              path,
              mCameraSetup.getJpegOrientation(),
              createTakePhotoResultListener(result)
      );
    } catch (CameraAccessException e) {
      result.error(e.getMessage(), "cannot open camera", "");
    }
  }

  private void _handleFlashMode(final MethodCall call, final Result result) {
    if(!call.hasArgument("mode")) {
      result.error("MODE_NOT_SET", "a mode must be set", "");
      return;
    }
    FlashMode flashmode = FlashMode.valueOf((String) call.argument("mode"));
    mCameraPreview.setFlashMode(flashmode);
    mCameraPicture.setFlashMode(flashmode);
    result.success(null);
  }

  private void _handleZoom(final MethodCall call, final Result result) {
    if(!call.hasArgument("zoom")) {
      result.error("ZOOM_NOT_SET", "a float zoom must be set", "");
      return;
    }
    double zoom = call.argument("zoom");
    // sending 0.0 will result in an int so lets force cast
    mCameraPreview.setZoom((float) zoom);
    result.success(null);
  }

  /**
   * Returns the max available zoom from device
   * @param call FLutter method call
   * @param result Flutter Result method
   */
  private void _handleGetMaxZoom(MethodCall call, Result result) {
    if(throwIfCameraNotInit(result))
      return;
    result.success(mCameraSetup.getCharacteristicsModel().getMaxZoom());
  }

  private void _handleAutoFocus(final MethodCall call, final Result result) {
    try {
      mCameraPreview.lockFocus();
      result.success(null);
    } catch (RuntimeException e) {
      result.error("NOT_FOCUSING", "not in focus", "");
    }
  }

  private CameraPicture.OnImageResult createTakePhotoResultListener(final Result result) {
    return new CameraPicture.OnImageResult() {
      boolean sent = false;

      @Override
      public void onSuccess() {
        if(sent) {
          return;
        }
        try {
          sent = true;
          result.success(null);
        } catch (IllegalStateException e) {
          Log.e(TAG, "onSuccess image error", e);
        }
      }

      @Override
      public void onFailure(String error) {
        if(sent) {
          return;
        }
        sent = true;
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

  public void setPluginActivity(Activity pluginActivity) {
    this.pluginActivity = pluginActivity;
  }

  // ----------------------------
  // ActivityAware
  // ----------------------------

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.pluginActivity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this.cameraPermissions);
    if (this.mCameraPreview != null)
      this.mCameraPreview.setMainHandler(new Handler(pluginActivity.getMainLooper()));
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    this.pluginActivity = null;
    this.mCameraPreview.setMainHandler(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    this.pluginActivity = binding.getActivity();
    binding.addRequestPermissionsResultListener(this.cameraPermissions);
    this.mCameraPreview.setMainHandler(new Handler(pluginActivity.getMainLooper()));
  }

  @Override
  public void onDetachedFromActivity() {
    this.pluginActivity = null;
    if(this.mCameraStateManager != null) {
      this.mCameraStateManager.stopCamera();
      this.mCameraStateManager = null;
    }
    if(this.mCameraPreview != null) {
      this.mCameraPreview.setMainHandler(null);
    }
  }
}
