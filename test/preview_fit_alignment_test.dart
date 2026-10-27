import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/widgets/preview/awesome_preview_fit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _textureKey = Key("texture");

Future<Rect> _pumpPreview(
  WidgetTester tester, {
  required Size screen,
  required PreviewSize previewSize,
  Alignment fitAlignment = Alignment.topLeft,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = screen;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedPreviewFit(
        fitAlignment: fitAlignment,
        previewFit: CameraPreviewFit.cover,
        previewSize: previewSize,
        constraints: BoxConstraints.tight(screen),
        sensor: Sensor.position(SensorPosition.back),
        child: const ColoredBox(key: _textureKey, color: Colors.black),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.getRect(find.byKey(_textureKey));
}

void main() {
  testWidgets("cover keeps the image anchored at the top-left by default",
      (tester) async {
    final preview = await _pumpPreview(
      tester,
      screen: const Size(360, 820),
      previewSize: PreviewSize(width: 480, height: 640),
    );

    expect(preview, rectMoreOrLessEquals(const Rect.fromLTWH(0, 0, 615, 820)));
  });

  testWidgets("cover crops both sides evenly with a centered fitAlignment",
      (tester) async {
    final preview = await _pumpPreview(
      tester,
      screen: const Size(360, 820),
      previewSize: PreviewSize(width: 480, height: 640),
      fitAlignment: Alignment.center,
    );

    expect(
      preview,
      rectMoreOrLessEquals(const Rect.fromLTWH(-127.5, 0, 615, 820)),
    );
  });

  testWidgets("cover crops top and bottom evenly with a centered fitAlignment",
      (tester) async {
    final preview = await _pumpPreview(
      tester,
      screen: const Size(820, 360),
      previewSize: PreviewSize(width: 640, height: 480),
      fitAlignment: Alignment.center,
    );

    expect(
      preview,
      rectMoreOrLessEquals(const Rect.fromLTWH(0, -127.5, 820, 615)),
    );
  });
}
