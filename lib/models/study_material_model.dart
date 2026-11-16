import 'dart:typed_data';

/// The kinds of study material a student can add to a course.
enum StudyMaterialKind {
  pdf('PDF', 'PDF document', 'Add PDF'),
  document('Document', 'Word document', 'Add Document'),
  presentation('Presentation', 'Presentation', 'Add Presentation'),
  image('Image', 'Image', 'Add Images'),
  photo('Photo', 'Camera photo', 'Take Photo'),
  text('Text', 'Typed notes', 'Add Text');

  const StudyMaterialKind(this.label, this.description, this.actionLabel);

  final String label;
  final String description;

  /// Label of the button shown on the "Add Study Material" screen.
  final String actionLabel;
}

/// One piece of study material supplied by the student.
///
/// [text] holds typed notes immediately, and will hold the text extracted from
/// files once document processing is added.
class StudyMaterialItem {
  const StudyMaterialItem({
    required this.name,
    required this.kind,
    this.sizeBytes,
    this.text,
    this.bytes,
    this.path,
  });

  final String name;
  final StudyMaterialKind kind;

  /// Size in bytes when known (files only).
  final int? sizeBytes;

  /// Typed or extracted text.
  final String? text;

  /// Raw file content when the platform provided it (always available on web).
  final Uint8List? bytes;

  /// Local file path when the platform provided one (mobile/desktop).
  ///
  /// Null on web, where [bytes] is used instead.
  final String? path;

  /// True when there is text the course generator can use.
  bool get hasText => (text ?? '').trim().isNotEmpty;

  /// True when readable file content was captured for later processing.
  bool get hasFileContent =>
      (bytes?.isNotEmpty ?? false) || (path ?? '').trim().isNotEmpty;

  /// Human readable size, e.g. "1.2 MB", falling back to the kind label.
  String get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null) return kind.description;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
