flutter pub run pigeon \
  --input pigeons/interface.dart \
  --dart_out lib/pigeon.dart \
  --experimental_kotlin_out ./android/src/main/kotlin/com/apparence/camerawesome/cameraX/Pigeon.kt \
  --experimental_kotlin_package "com.apparence.camerawesome.cameraX" \
  --objc_source_out ./ios/Classes/Pigeon/Pigeon.m \
  --objc_header_out ./ios/Classes/Pigeon/Pigeon.h \