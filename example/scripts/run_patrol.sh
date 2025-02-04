# Activate patrol cli
#dart pub global activate patrol_cli

# Run all tests
#patrol drive --target integration_test/bundled_test.dart
patrol test --target integration_test/bundled_test.dart

# Or only run specific tests
#patrol drive \
#  --target integration_test/ui_test.dart \
#  --target integration_test/photo_test.dart \
#  --target integration_test/video_test.dart
