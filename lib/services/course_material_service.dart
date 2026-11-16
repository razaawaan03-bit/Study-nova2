import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../models/processed_material_model.dart';
import '../models/study_material_model.dart';
import '../utils/material_file_reader.dart';

/// Turns the study material selected in the Course Maker into content that the
/// AI course-generation stage can use.
///
/// This service never touches the network and never calls the Gemini API: it
/// only prepares readable text and binary content. AIStudyService stays
/// responsible for every model call, so the current Gemini configuration and
/// its retry/fallback handling are untouched.
class CourseMaterialService {
  const CourseMaterialService();

  /// Same per-file limit used when picking material.
  static const int maxFileBytes = 20 * 1024 * 1024;

  static const String _pdfMimeType = 'application/pdf';
  static const String _docxMimeType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  static const String _pptxMimeType =
      'application/vnd.openxmlformats-officedocument.presentationml.presentation';
  static const String _docMimeType = 'application/msword';
  static const String _pptMimeType = 'application/vnd.ms-powerpoint';

  /// Processes every material, preserving the order they were added in.
  Future<MaterialProcessingResult> process(
    List<StudyMaterialItem> items, {
    void Function(int done, int total)? onProgress,
  }) async {
    final processed = <ProcessedMaterial>[];
    final total = items.length;

    for (var index = 0; index < total; index++) {
      onProgress?.call(index, total);
      processed.add(await _processOne(items[index]));
    }
    onProgress?.call(total, total);

    return MaterialProcessingResult(processed);
  }

  Future<ProcessedMaterial> _processOne(StudyMaterialItem item) async {
    switch (item.kind) {
      case StudyMaterialKind.text:
        return _processText(item);
      case StudyMaterialKind.pdf:
        return _processBinary(item, _pdfMimeType);
      case StudyMaterialKind.image:
        return _processBinary(item, _imageMimeType(item.name));
      case StudyMaterialKind.photo:
        return _processBinary(item, _imageMimeType(item.name));
      case StudyMaterialKind.document:
        return _processWordDocument(item);
      case StudyMaterialKind.presentation:
        return _processPresentation(item);
    }
  }

  /// Typed notes are passed through exactly as the student wrote them.
  ProcessedMaterial _processText(StudyMaterialItem item) {
    final text = item.text ?? '';
    if (text.trim().isEmpty) {
      return _failed(
        item,
        'That note is empty. Please type or paste some text.',
      );
    }
    return ProcessedMaterial(
      name: item.name,
      kind: item.kind,
      status: MaterialProcessingStatus.ready,
      mimeType: 'text/plain',
      text: text,
    );
  }

  /// PDFs and images are kept as binary data for multimodal AI input.
  Future<ProcessedMaterial> _processBinary(
    StudyMaterialItem item,
    String mimeType,
  ) async {
    final bytes = await _resolveBytes(item);

    if (bytes == null || bytes.isEmpty) {
      return _failed(
        item,
        'Could not read "${item.name}". Please try another file.',
      );
    }
    if (bytes.length > maxFileBytes) {
      return _failed(
        item,
        '"${item.name}" is larger than 20 MB. Please choose a smaller file.',
      );
    }

    return ProcessedMaterial(
      name: item.name,
      kind: item.kind,
      status: MaterialProcessingStatus.ready,
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  /// Prefers the bytes captured while picking and falls back to reading the
  /// local path (needed where the picker only returns a path).
  Future<Uint8List?> _resolveBytes(StudyMaterialItem item) async {
    final captured = item.bytes;
    if (captured != null && captured.isNotEmpty) return captured;

    final path = item.path;
    if (path == null || path.trim().isEmpty) return null;

    return readBytesFromPath(path);
  }

  Future<ProcessedMaterial> _processWordDocument(StudyMaterialItem item) async {
    final extension = _extensionOf(item.name);

    // A DOCX is a zip archive with XML we can read locally.
    if (extension == 'docx') {
      final bytes = await _resolveBytes(item);
      if (bytes == null || bytes.isEmpty) {
        return _failed(
          item,
          'Could not read "${item.name}". Please try another file.',
        );
      }

      final text = _extractDocxText(bytes);
      if (text == null || text.isEmpty) {
        return _failed(
          item,
          'Could not read "${item.name}". Please try another file.',
        );
      }

      return ProcessedMaterial(
        name: item.name,
        kind: item.kind,
        status: MaterialProcessingStatus.ready,
        mimeType: _docxMimeType,
        text: text,
      );
    }

    // Legacy binary .doc cannot be parsed reliably, so say so plainly.
    if (extension == 'doc') {
      return ProcessedMaterial(
        name: item.name,
        kind: item.kind,
        status: MaterialProcessingStatus.needsConversion,
        mimeType: _docMimeType,
        bytes: await _resolveBytes(item),
        message:
            '"${item.name}" may need to be converted to DOCX before StudyNova '
            'can read its text.',
      );
    }

    return _failed(item, '"${item.name}" is not a supported file type.');
  }

  Future<ProcessedMaterial> _processPresentation(StudyMaterialItem item) async {
    final extension = _extensionOf(item.name);

    // A PPTX is a zip archive whose slides hold the readable text.
    if (extension == 'pptx') {
      final bytes = await _resolveBytes(item);
      if (bytes == null || bytes.isEmpty) {
        return _failed(
          item,
          'Could not read "${item.name}". Please try another file.',
        );
      }

      final text = _extractPptxText(bytes);
      if (text == null || text.isEmpty) {
        return _failed(
          item,
          'Could not read "${item.name}". Please try another file.',
        );
      }

      return ProcessedMaterial(
        name: item.name,
        kind: item.kind,
        status: MaterialProcessingStatus.ready,
        mimeType: _pptxMimeType,
        text: text,
      );
    }

    // Legacy binary .ppt cannot be parsed reliably, so say so plainly.
    if (extension == 'ppt') {
      return ProcessedMaterial(
        name: item.name,
        kind: item.kind,
        status: MaterialProcessingStatus.needsConversion,
        mimeType: _pptMimeType,
        bytes: await _resolveBytes(item),
        message:
            '"${item.name}" may need to be converted to PPTX before StudyNova '
            'can read its text.',
      );
    }

    return _failed(item, '"${item.name}" is not a supported file type.');
  }

  /// Reads the paragraph text out of `word/document.xml`.
  String? _extractDocxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entry = _findEntry(archive, 'word/document.xml');
      final content = entry?.readBytes();
      if (content == null) return null;

      return _paragraphText(utf8.decode(content, allowMalformed: true));
    } catch (_) {
      return null;
    }
  }

  /// Reads the text of every slide, keeping slide order.
  String? _extractPptxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final slidePattern = RegExp(r'^ppt/slides/slide(\d+)\.xml$');
      final slides = <int, ArchiveFile>{};

      for (final file in archive.files) {
        final match = slidePattern.firstMatch(file.name);
        if (match == null) continue;
        final number = int.tryParse(match.group(1) ?? '');
        if (number != null) slides[number] = file;
      }
      if (slides.isEmpty) return null;

      final numbers = slides.keys.toList()..sort();
      final buffer = StringBuffer();

      for (final number in numbers) {
        final content = slides[number]?.readBytes();
        if (content == null) continue;

        final text = _paragraphText(utf8.decode(content, allowMalformed: true));
        if (text.isEmpty) continue;

        buffer.writeln('Slide $number');
        buffer.writeln(text);
        buffer.writeln();
      }

      final result = buffer.toString().trim();
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  ArchiveFile? _findEntry(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.name == name) return file;
    }
    return null;
  }

  /// Collects the text of every paragraph in an Office XML document.
  ///
  /// Word names a paragraph `w:p` and PowerPoint names it `a:p`; both keep
  /// their readable text in `t` elements, so one walk serves both formats.
  String _paragraphText(String xmlSource) {
    final document = XmlDocument.parse(xmlSource);
    final buffer = StringBuffer();

    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.name.local != 'p') continue;

      final line = element.descendants
          .whereType<XmlElement>()
          .where((child) => child.name.local == 't')
          .map((child) => child.innerText)
          .join();

      if (line.trim().isNotEmpty) buffer.writeln(line.trim());
    }

    return buffer.toString().trim();
  }

  /// Reasonable MIME type for the image formats StudyNova accepts.
  static String _imageMimeType(String fileName) {
    switch (_extensionOf(fileName)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  /// Lowercase extension without the dot, or an empty string.
  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  ProcessedMaterial _failed(StudyMaterialItem item, String message) {
    return ProcessedMaterial(
      name: item.name,
      kind: item.kind,
      status: MaterialProcessingStatus.failed,
      message: message,
    );
  }
}
