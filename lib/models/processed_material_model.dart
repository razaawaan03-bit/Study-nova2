import 'dart:typed_data';

import 'study_material_model.dart';

/// Outcome of processing one piece of study material.
enum MaterialProcessingStatus {
  /// Content is ready to be used by the AI course-generation stage.
  ready,

  /// The file exists but its text/content could not be read.
  failed,

  /// The format cannot be read locally and needs converting first.
  needsConversion,
}

/// One piece of study material after processing.
///
/// This is the hand-off object for the course-generation stage: it carries
/// either readable [text] or binary [bytes] plus the [mimeType] needed to send
/// them to the AI as multimodal input.
class ProcessedMaterial {
  const ProcessedMaterial({
    required this.name,
    required this.kind,
    required this.status,
    this.mimeType,
    this.text,
    this.bytes,
    this.message,
  });

  /// Original file name (or note name).
  final String name;

  final StudyMaterialKind kind;
  final MaterialProcessingStatus status;

  /// MIME type when the material is sent as binary content.
  final String? mimeType;

  /// Extracted or typed text, when this material contributes text.
  final String? text;

  /// Binary content for multimodal (image / PDF) input.
  final Uint8List? bytes;

  /// Friendly explanation for the student. Never a raw exception.
  final String? message;

  /// True when the course-generation stage can use this material.
  bool get isReady => status == MaterialProcessingStatus.ready;

  /// True when the material carries binary content for multimodal input.
  bool get hasBytes => bytes?.isNotEmpty ?? false;

  /// True when the material carries usable text.
  bool get hasText => (text ?? '').trim().isNotEmpty;

  /// Short status line used by the temporary Stage 3 summary.
  String get statusLabel {
    switch (status) {
      case MaterialProcessingStatus.ready:
        if (hasText) return 'Ready - ${text!.trim().length} characters of text';
        if (hasBytes) return 'Ready - ${mimeType ?? kind.label} content';
        return 'Ready';
      case MaterialProcessingStatus.needsConversion:
        return 'Needs conversion';
      case MaterialProcessingStatus.failed:
        return 'Could not be read';
    }
  }
}

/// Result of processing every selected material.
class MaterialProcessingResult {
  const MaterialProcessingResult(this.items);

  final List<ProcessedMaterial> items;

  int get readyCount => items.where((item) => item.isReady).length;

  int get failedCount => items
      .where((item) => item.status == MaterialProcessingStatus.failed)
      .length;

  int get needsConversionCount => items
      .where((item) => item.status == MaterialProcessingStatus.needsConversion)
      .length;

  /// True when at least one material can be handed to the AI stage.
  bool get hasUsableMaterial => readyCount > 0;

  /// Friendly one-line summary, e.g. "2 of 3 ready • 1 needs conversion".
  String get summaryMessage {
    if (items.isEmpty) return 'No material was added.';
    final parts = <String>['$readyCount of ${items.length} ready'];
    if (needsConversionCount > 0) {
      parts.add('$needsConversionCount needs conversion');
    }
    if (failedCount > 0) {
      parts.add('$failedCount could not be read');
    }
    return parts.join(' • ');
  }
}
