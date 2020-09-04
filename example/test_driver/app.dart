import 'dart:io';

import 'package:camerawesome/camerapreview.dart';
import 'package:camerawesome_example/main.dart' as app;
import 'package:camerawesome_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as imgUtils;

/// -------------------------------------------
/// Integretions test
/// -------------------------------------------
/// start these with :
/// flutter drive --driver=test_driver/app_test.dart test_driver/app.dart
/// or for android native : (first go in android folder of example)
/// ./gradlew app:connectedAndroidTest -Ptarget=`pwd`/../test_driver/app.dart
/// or for iOS native :
///
void main() {

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("start camera preview", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp(randomPhotoName: true)));
    await tester.pumpAndSettle(Duration(seconds: 1));
    var camera = find.byType(CameraAwesome);
    await expectLater(camera, findsOneWidget);
    var cameraPreview = camera.evaluate().first.widget as CameraAwesome;
  });

  testWidgets("take photo works with selected photo size", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp(randomPhotoName: true)));
    await tester.pumpAndSettle(Duration(seconds: 1));
    var camera = find.byType(CameraAwesome);
    await expectLater(camera, findsOneWidget);
    var cameraPreview = camera.evaluate().first.widget as CameraAwesome;
    var takePhotoBtnFinder = find.byKey(ValueKey("takePhotoButton"));
    // take photo
    await tester.tap(takePhotoBtnFinder);
    await tester.pump(Duration(seconds: 2));
    expect(cameraPreview.photoSize.value, isNotNull);
    // checks photo exists + size
    final Directory extDir = await getTemporaryDirectory();
    var testDir = await Directory('${extDir.path}/test');
    final String filePath = '${testDir.path}/photo_test.jpg';
    expect(await File(filePath).exists(), isTrue);
    var file = await File(filePath);
    var img = imgUtils.decodeImage(file.readAsBytesSync());
    expect(img.width, equals(cameraPreview.photoSize.value.width));
    expect(img.height, equals(cameraPreview.photoSize.value.height));
    // delete photo
    file.deleteSync();
  });

  testWidgets("change selected photo size param then take photo", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp(randomPhotoName: true)));
    await tester.pumpAndSettle(Duration(seconds: 1));
    var camera = find.byType(CameraAwesome);
    await expectLater(camera, findsOneWidget);
    var cameraPreview = camera.evaluate().first.widget as CameraAwesome;
    var takePhotoBtnFinder = find.byKey(ValueKey("takePhotoButton"));
    // change photo size preset
    var previousResolution = (find.byKey(ValueKey("resolutionTxt")).evaluate().first.widget as Text).data;
    await tester.tap(find.byKey(ValueKey("resolutionButton")));
    await tester.pump(Duration(milliseconds: 1000));
    await tester.pumpAndSettle(Duration(milliseconds: 1000));
    await tester.tap(find.byKey(ValueKey("resOption")).at(1));
    await tester.pump(Duration(milliseconds: 500));
    var currentResolution = (find.byKey(ValueKey("resolutionTxt")).evaluate().first.widget as Text).data;
    expect(previousResolution, isNot(equals(currentResolution)));
    // take photo
    await tester.tap(takePhotoBtnFinder);
    await tester.pump(Duration(seconds: 2));
    // checks photo exists + size
    final Directory extDir = await getTemporaryDirectory();
    var testDir = await Directory('${extDir.path}/test');
    final String filePath = '${testDir.path}/photo_test.jpg';
    expect(await File(filePath).exists(), isTrue);
    var file = await File(filePath);
    var img = imgUtils.decodeImage(file.readAsBytesSync());
    expect(img.width, equals(cameraPreview.photoSize.value.width));
    expect(img.height, equals(cameraPreview.photoSize.value.height));
    // delete photo
    file.deleteSync();
  });
}