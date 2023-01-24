package com.apparence.camerawesome.exceptions

class PermissionNotDeclaredException(permission: String) :
    Exception("Permission not declared: $permission\nAdd it to your AndroidManifest.xml:\n<uses-permission android:name=\"$permission\" />") {
}