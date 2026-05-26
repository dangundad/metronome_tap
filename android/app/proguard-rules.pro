# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# AdMob mediation: AppLovin
-keep class com.applovin.** { *; }
-dontwarn com.applovin.**

# AdMob mediation: Pangle
-keep class com.bytedance.** { *; }
-dontwarn com.bytedance.**

# AdMob mediation: Unity Ads
-keep class com.unity3d.ads.** { *; }
-dontwarn com.unity3d.ads.**

# Google Play Billing
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.** { *; }
-dontwarn com.google.android.play.core.**

# Keep annotations and signatures used by generated code and platform channels.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
