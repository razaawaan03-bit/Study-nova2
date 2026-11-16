import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Brings ImageSource, XFile, ImagePickerOptions and ImagePickerPlatform. The
// platform interface is a declared dev_dependency because `image_picker` does
// not re-export `ImagePickerPlatform`, which is what has to be replaced.
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:studynova/screens/study_from_photo/study_from_photo_screen.dart';

/// Records which [ImageSource] the screen asked for.
///
/// The requirement is that the camera button opens the camera and the gallery
/// button opens the gallery. Tapping both and inspecting the recorded source is
/// the only way to prove they are actually different, rather than trusting the
/// button labels.
class _RecordingPicker extends ImagePickerPlatform {
  final List<ImageSource> sources = <ImageSource>[];

  /// When true the pick fails, standing in for a denied permission or a device
  /// with no camera app.
  bool failNext = false;

  /// When true the pick resolves to nothing, standing in for the student
  /// backing out of the camera or gallery. The screen then stays put, which
  /// lets both buttons be exercised on one screen.
  bool cancelNext = false;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    sources.add(source);
    if (failNext) {
      failNext = false;
      throw Exception('simulated camera/gallery failure');
    }
    if (cancelNext) {
      cancelNext = false;
      return null;
    }
    // A 1x1 transparent PNG, returned from memory so nothing touches the disk.
    return XFile.fromData(
      onePixelPng,
      name: 'study_image.jpg',
      mimeType: 'image/jpeg',
    );
  }
}

void main() {
  late ImagePickerPlatform original;

  setUp(() {
    original = ImagePickerPlatform.instance;
  });

  tearDown(() {
    ImagePickerPlatform.instance = original;
  });

  Future<_RecordingPicker> pumpScreen(WidgetTester tester) async {
    final picker = _RecordingPicker();
    ImagePickerPlatform.instance = picker;
    await tester.pumpWidget(const MaterialApp(home: StudyFromPhotoScreen()));
    await tester.pumpAndSettle();
    return picker;
  }

  testWidgets('"Take a Photo" opens the camera', (tester) async {
    final picker = await pumpScreen(tester);

    await tester.tap(find.text('Take a Photo'));
    await tester.pump();

    expect(picker.sources, <ImageSource>[ImageSource.camera]);
  });

  testWidgets('"Choose from Gallery" opens the gallery', (tester) async {
    final picker = await pumpScreen(tester);

    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump();

    expect(picker.sources, <ImageSource>[ImageSource.gallery]);
  });

  testWidgets('the two buttons never both open the gallery', (tester) async {
    // The regression this guards against: both entries wired to the gallery, so
    // the camera is unreachable on a phone. Each pick is cancelled so the screen
    // stays put and both buttons can be exercised on it.
    final picker = await pumpScreen(tester);

    picker.cancelNext = true;
    await tester.tap(find.text('Take a Photo'));
    await tester.pumpAndSettle();
    expect(picker.sources, <ImageSource>[ImageSource.camera]);

    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpAndSettle();

    expect(picker.sources, <ImageSource>[
      ImageSource.camera,
      ImageSource.gallery,
    ]);
    expect(picker.sources.toSet(), hasLength(2));
  });

  testWidgets('a failed camera pick leaves the student on the screen', (
    tester,
  ) async {
    // Covers a denied permission and a device with no camera app: the app must
    // stay put, show a sentence the student can act on, and let them retry.
    final picker = await pumpScreen(tester);
    picker.failNext = true;

    await tester.tap(find.text('Take a Photo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Capture Your Study Material'), findsOneWidget);
    expect(
      find.textContaining('camera'),
      findsWidgets,
      reason: 'the message should point at the camera',
    );

    // The button works again afterwards.
    await tester.tap(find.text('Take a Photo'));
    await tester.pump();
    expect(picker.sources, <ImageSource>[
      ImageSource.camera,
      ImageSource.camera,
    ]);
  });

  testWidgets('the picked image is previewed from memory, not a file', (
    tester,
  ) async {
    // `Image.file` / `dart:io` do not work on Flutter Web, so the analysis
    // screen must be given bytes. Reaching it proves the flow handed over bytes.
    final picker = await pumpScreen(tester);

    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpAndSettle();

    // The analysis screen opened, showing the review UI for the picked image.
    expect(find.text('Review & Analyze'), findsOneWidget);
    expect(find.text('Choose Explanation Level'), findsOneWidget);
    expect(picker.sources, <ImageSource>[ImageSource.gallery]);
    expect(tester.takeException(), isNull);
  });
}

/// A valid 1x1 transparent PNG.
final Uint8List onePixelPng = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
