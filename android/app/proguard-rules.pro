# Vynex ProGuard Rules
# Keep mobile_scanner classes
-keep class dev.steenbakker.mobile_scanner.** { *; }

-keep class com.google.mlkit.** { *; }

-keep class com.google.android.gms.** { *; }

-dontwarn com.google.mlkit.**

-dontwarn com.google.android.gms.**

# Keep ZXing barcode library (used by mobile_scanner)
-keep class com.google.zxing.** { *; }

-dontwarn com.google.zxing.**

# Keep CameraX classes used by mobile_scanner
-keep class androidx.camera.** { *; }

-dontwarn androidx.camera.**

# Keep Flutter plugin registrar
-keep class io.flutter.plugin.** { *; }

-keep class io.flutter.embedding.** { *; }

# General Flutter rules
-keep class io.flutter.app.** { *; }

-keep class io.flutter.view.** { *; }

-keep class io.flutter.** { *; }

-dontwarn io.flutter.**

# Keep all annotations
-keepattributes Annotation

-keepattributes Signature

-keepattributes Exceptions

-keepattributes InnerClasses

-keepattributes EnclosingMethod

# Prevent obfuscation of classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
