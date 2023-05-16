SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "${SCRIPT_DIR}/../android"
./gradlew :app:connectedDebugAndroidTest -Ptarget=$(pwd)/../integration_test/concurrent_camera_test.dart
popd