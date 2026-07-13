# ============================================================
# ProGuard/R8 keep-rules для Crazy Trout Arena CRM
#
# При minifyEnabled=true R8 вырезает ВСЕ классы без keep-rule,
# включая Flutter plugin registrant (GeneratedPluginRegistrant),
# который запускается ДО любого пользовательского кода.
# Без этих правил приложение крашится сразу при старте.
# ============================================================

# --- Flutter embedding (обязательно при minifyEnabled) ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- mobile_scanner / CameraX / ML Kit Barcode Scanning ---
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.vision.codescanner.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
# ВАЖНО: com.google.mlkit.common.** (без .vision) — это ядро ML Kit
# (MlKitInitProvider, DI-контейнер sdkinternal.*). Без этого правила R8
# вырезает com.google.mlkit.common.sdkinternal.d как "неиспользуемый"
# (он подключается через рефлексию/DI, а не прямые вызовы), и приложение
# крашится СРАЗУ при старте — ContentProvider ML Kit регистрируется в
# AndroidManifest и запускается до какого-либо Dart/Flutter кода.
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class androidx.camera.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision_barcode.**
-dontwarn com.google.android.gms.internal.mlkit_vision_common.**
-dontwarn com.google.android.gms.internal.mlkit_common.**
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
