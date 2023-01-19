SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "${SCRIPT_DIR}/../android"
# flutter build generates files in android/ for building the app
flutter build apk
./gradlew app:assembleDebugAndroidTest
./gradlew app:assembleDebug -Ptarget=`pwd`/../integration_test/bundled_test.dart

popd


gcloud auth activate-service-account --key-file="${SCRIPT_DIR}/../../camerawesome-6e777-13db0fddbbe5.json"
gcloud --quiet config set project camerawesome-6e777

gcloud firebase test android run --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=cheetah,version=33,locale=en,orientation=portrait \
  --timeout 15m
#  --results-bucket=<RESULTS_BUCKET> \
#  --results-dir=<RESULTS_DIRECTORY>

