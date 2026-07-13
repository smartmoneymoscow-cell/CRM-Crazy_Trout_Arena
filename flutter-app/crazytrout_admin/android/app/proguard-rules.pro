# ============================================================
# ProGuard/R8 keep-rules для Crazy Trout Arena CRM
# ============================================================

# --- Flutter embedding (обязательно при minifyEnabled) ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- ML Kit common (DI-система, MlKitInitProvider) ---
# Без этого правила R8 вырезает com.google.mlkit.common.sdkinternal.*
# → MlKitInitProvider крашится при старте с "Unsatisfied dependency"
-keep class com.google.mlkit.common.** { *; }
-dontwarn com.google.mlkit.common.**

# --- mobile_scanner / CameraX / ML Kit Barcode Scanning ---
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.vision.codescanner.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision_barcode.**
-dontwarn com.google.android.gms.internal.mlkit_vision_common.**
-dontwarn androidx.camera.**

# --- flutter_blue_plus (Bluetooth-печать) ---
-keep class com.lib.flutter_blue_plus.** { *; }
-dontwarn com.lib.flutter_blue_plus.**

# --- printing / pdf (системный диалог печати) ---
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# --- permission_handler ---
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**
