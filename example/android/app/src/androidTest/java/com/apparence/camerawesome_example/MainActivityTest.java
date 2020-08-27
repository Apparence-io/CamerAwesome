package com.apparence.camerawesome_example;

import android.Manifest.permission;
import androidx.test.rule.ActivityTestRule;
import androidx.test.rule.GrantPermissionRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;
import io.flutter.embedding.android.FlutterActivity;

@RunWith(FlutterTestRunner.class)
public class MainActivityTest {

    @Rule
    public GrantPermissionRule permissionRule = GrantPermissionRule.grant(
            permission.WRITE_EXTERNAL_STORAGE,
            permission.CAMERA
    );

    @Rule
    public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class, true, false);
}