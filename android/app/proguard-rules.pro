# Flutter specific rules for ProGuard.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-dontwarn io.flutter.embedding.**
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers class ** {
    @io.flutter.plugin.common.Keep public *;
}
