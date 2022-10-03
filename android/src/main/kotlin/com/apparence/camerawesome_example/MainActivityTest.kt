package com.apparence.camerawesome_example

import android.Manifest
import androidx.test.rule.ActivityTestRule

@RunWith(FlutterTestRunner::class)
class MainActivityTest {
    @Rule
    var permissionRule: GrantPermissionRule = GrantPermissionRule.grant(
        Manifest.permission.WRITE_EXTERNAL_STORAGE,
        Manifest.permission.CAMERA
    )

    @Rule
    var rule: ActivityTestRule<MainActivity> =
        ActivityTestRule(MainActivity::class.java, true, false)
}