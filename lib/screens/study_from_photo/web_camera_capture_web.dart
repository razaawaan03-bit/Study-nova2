import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';

abstract class WebCameraCaptureLauncher {
  static Future<Uint8List?> launch(BuildContext context) async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw StateError(
        'This browser does not support webcam access. Please use Chrome or Edge.',
      );
    }

    if (!(html.window.isSecureContext ?? false)) {
      throw StateError(
        'Camera access requires a secure context. Open this page via localhost or HTTPS and try again.',
      );
    }

    final stream = await _requestCameraStream(mediaDevices);
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..setAttribute('controls', 'false')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    final overlay = html.DivElement()
      ..style.position = 'fixed'
      ..style.left = '0'
      ..style.top = '0'
      ..style.right = '0'
      ..style.bottom = '0'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.background = 'rgba(15, 23, 42, 0.7)'
      ..style.zIndex = '2147483647'
      ..style.padding = '20px';

    final panel = html.DivElement()
      ..style.width = 'min(92vw, 540px)'
      ..style.borderRadius = '18px'
      ..style.background = '#ffffff'
      ..style.boxShadow = '0 18px 50px rgba(0,0,0,0.28)'
      ..style.padding = '18px'
      ..style.display = 'flex'
      ..style.flexDirection = 'column'
      ..style.gap = '14px';

    final title = html.HeadingElement.h2()
      ..text = 'Capture Photo'
      ..style.margin = '0'
      ..style.fontFamily = 'sans-serif'
      ..style.color = '#0f172a'
      ..style.fontSize = '22px';

    final hint = html.ParagraphElement()
      ..text = 'Use your webcam and press Capture Photo when ready.'
      ..style.margin = '0'
      ..style.fontFamily = 'sans-serif'
      ..style.color = '#475569'
      ..style.fontSize = '14px';

    final videoWrap = html.DivElement()
      ..style.width = '100%'
      ..style.aspectRatio = '4 / 3'
      ..style.background = '#0f172a'
      ..style.borderRadius = '12px'
      ..style.overflow = 'hidden'
      ..style.boxSizing = 'border-box';

    final actions = html.DivElement()
      ..style.display = 'flex'
      ..style.justifyContent = 'flex-end'
      ..style.gap = '10px';

    final cancelButton = html.ButtonElement()
      ..text = 'Cancel'
      ..style.padding = '10px 16px'
      ..style.border = '1px solid #cbd5e1'
      ..style.borderRadius = '10px'
      ..style.background = '#ffffff'
      ..style.color = '#0f172a'
      ..style.cursor = 'pointer';

    final captureButton = html.ButtonElement()
      ..text = 'Capture Photo'
      ..style.padding = '10px 16px'
      ..style.border = 'none'
      ..style.borderRadius = '10px'
      ..style.background = '#2563eb'
      ..style.color = '#ffffff'
      ..style.cursor = 'pointer';

    final result = Completer<Uint8List?>();

    void closeStream() {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      video.srcObject = null;
      overlay.remove();
    }

    cancelButton.onClick.listen((_) {
      closeStream();
      if (!result.isCompleted) {
        result.complete(null);
      }
    });

    captureButton.onClick.listen((_) {
      if (result.isCompleted) return;

      try {
        final width = video.videoWidth;
        final height = video.videoHeight;
        if (width <= 0 || height <= 0) {
          throw StateError(
            'The webcam stream is not ready yet. Please try again.',
          );
        }

        final canvas = html.CanvasElement(width: width, height: height);
        final canvasContext =
            canvas.getContext('2d') as html.CanvasRenderingContext2D?;
        if (canvasContext == null) {
          throw StateError('The browser could not prepare the camera frame.');
        }

        canvasContext.drawImage(video, 0, 0);

        final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);
        final uriData = Uri.parse(dataUrl).data;
        final bytes = uriData?.contentAsBytes() ?? Uint8List(0);

        closeStream();
        if (bytes.isEmpty) {
          result.complete(null);
        } else {
          result.complete(bytes);
        }
      } catch (error) {
        closeStream();
        result.completeError(error);
      }
    });

    actions.append(cancelButton);
    actions.append(captureButton);
    videoWrap.append(video);
    panel.append(title);
    panel.append(hint);
    panel.append(videoWrap);
    panel.append(actions);
    overlay.append(panel);
    html.document.body?.append(overlay);

    video.srcObject = stream;
    await video.onLoadedMetadata.first;
    await video.play();

    return result.future;
  }

  static Future<html.MediaStream> _requestCameraStream(
    html.MediaDevices mediaDevices,
  ) async {
    try {
      final constraints = {
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      };

      return await mediaDevices.getUserMedia(constraints);
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('denied') || message.contains('not allowed')) {
        throw StateError(
          'Camera permission was denied. Please allow camera access in Chrome and try again.',
        );
      }
      if (message.contains('not found') || message.contains('no camera')) {
        throw StateError('No webcam was found on this device.');
      }
      if (message.contains('secure') || message.contains('https')) {
        throw StateError(
          'Camera access requires a secure context. Open this page via localhost or HTTPS.',
        );
      }
      throw StateError(
        'The browser could not open the webcam. Please check your camera settings and try again.',
      );
    }
  }
}
