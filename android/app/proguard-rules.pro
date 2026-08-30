# flutter_local_notifications uses Gson reflection to persist scheduled
# notifications; keep its models and Gson metadata.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Google Mobile Ads / Play Services (defensive)
-keep class com.google.android.gms.ads.** { *; }

# Play Core / deferred components referenced by the Flutter engine
-dontwarn com.google.android.play.core.**
