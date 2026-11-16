# Keep JNI and reflection signatures required by Flutter Android plugins
# (e.g., shared_preferences_android 2.5.0 JNI bindings & package:jni Kotlin coroutines).
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep interface kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
