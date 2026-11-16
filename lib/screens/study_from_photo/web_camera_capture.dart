import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'web_camera_capture_stub.dart'
    if (dart.library.html) 'web_camera_capture_web.dart';

Future<Uint8List?> launchWebCameraCapture(BuildContext context) =>
    WebCameraCaptureLauncher.launch(context);
