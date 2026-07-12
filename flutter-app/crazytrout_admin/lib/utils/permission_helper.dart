import 'package:permission_handler/permission_handler.dart';

/// Обёртка для permission_handler через deferred-импорт.
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}
