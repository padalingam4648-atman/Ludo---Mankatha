# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Audioplayers plugin
-keep class xyz.luan.audioplayers.** { *; }

# Google Fonts
-keep class com.google.fonts.** { *; }

# Provider
-keep class provider.** { *; }

# Flutter Animate
-keep class flutter_animate.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Crypto
-keep class crypto.** { *; }

# General Android rules
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**