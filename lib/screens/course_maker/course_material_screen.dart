import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/course_content_model.dart';
import '../../models/course_model.dart';
import '../../models/processed_material_model.dart';
import '../../models/study_material_model.dart';
import '../../services/course_ai_service.dart';
import '../../services/course_material_service.dart';
import 'course_preview_screen.dart';

/// Step 2 of the Course Maker: "Add Study Material".
///
/// Lets the student pick PDF / Word / PowerPoint files, images from the
/// gallery or the camera, or type notes. Picked content is only collected and
/// listed here - reading it into course content happens in the next stage.
class CourseMaterialScreen extends StatefulWidget {
  const CourseMaterialScreen({super.key, required this.course});

  /// The draft course created in the previous step.
  final CourseModel course;

  @override
  State<CourseMaterialScreen> createState() => _CourseMaterialScreenState();
}

class _CourseMaterialScreenState extends State<CourseMaterialScreen> {
  /// Same friendly limit Study From Photo uses for inline AI requests.
  static const int _maxFileBytes = 20 * 1024 * 1024;

  /// Keeps a single pick reasonable and bounds how much is held in memory.
  static const int _maxFilesPerPick = 5;

  final List<StudyMaterialItem> _material = <StudyMaterialItem>[];
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final CourseMaterialService _materialService = const CourseMaterialService();
  final CourseAiService _courseAiService = const CourseAiService();

  bool _isProcessing = false;

  /// Label shown inside the loading button.
  String _progressLabel = 'Preparing your study material...';

  /// Stage 3 only: proves the picked material was processed. Stage 4 replaces
  /// this with the generated course preview.
  MaterialProcessingResult? _processingResult;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int get _typedTextCount =>
      _material.where((item) => item.kind == StudyMaterialKind.text).length;

  void _addTypedText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showMessage('Please type or paste some notes first.');
      return;
    }

    setState(() {
      _material.add(
        StudyMaterialItem(
          name: 'Typed notes ${_typedTextCount + 1}',
          kind: StudyMaterialKind.text,
          text: text,
        ),
      );
      _textController.clear();
      _processingResult = null;
    });
  }

  Future<void> _onMaterialTap(StudyMaterialKind kind) async {
    switch (kind) {
      case StudyMaterialKind.pdf:
        await _pickDocuments(const <String>['pdf'], StudyMaterialKind.pdf);
        return;
      case StudyMaterialKind.document:
        await _pickDocuments(const <String>[
          'doc',
          'docx',
        ], StudyMaterialKind.document);
        return;
      case StudyMaterialKind.presentation:
        await _pickDocuments(const <String>[
          'ppt',
          'pptx',
        ], StudyMaterialKind.presentation);
        return;
      case StudyMaterialKind.image:
        await _pickImages();
        return;
      case StudyMaterialKind.photo:
        await _takePhoto();
        return;
      case StudyMaterialKind.text:
        _showMessage('Type or paste your notes in the box below.');
        return;
    }
  }

  /// Picks one or more documents and adds them to the material list.
  Future<void> _pickDocuments(
    List<String> extensions,
    StudyMaterialKind kind,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: true,
      );

      // Null (or empty) means the student cancelled the picker.
      final picked = result?.files ?? const <PlatformFile>[];
      if (picked.isEmpty) return;

      final added = <StudyMaterialItem>[];
      String? problem;

      for (final file in picked) {
        if (added.length >= _maxFilesPerPick) {
          problem = 'You can add up to $_maxFilesPerPick files at a time.';
          break;
        }
        if (!_hasExtension(file.name, extensions)) {
          problem = '"${file.name}" is not a supported file type.';
          continue;
        }
        if (file.size > _maxFileBytes) {
          problem =
              '"${file.name}" is larger than 20 MB. '
              'Please choose a smaller file.';
          continue;
        }
        if (file.bytes == null && (file.path ?? '').trim().isEmpty) {
          problem = 'Could not read "${file.name}". Please try another file.';
          continue;
        }

        added.add(
          StudyMaterialItem(
            name: file.name,
            kind: kind,
            sizeBytes: file.size,
            bytes: file.bytes,
            path: file.path,
          ),
        );
      }

      if (added.isNotEmpty) {
        setState(() {
          _material.addAll(added);
          _processingResult = null;
        });
      }
      _showMessage(
        problem ??
            'Added ${added.length} ${added.length == 1 ? 'file' : 'files'}.',
      );
    } catch (_) {
      _showMessage('Could not open the file picker. Please try again.');
    }
  }

  /// Picks one or more images from the gallery.
  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return; // cancelled
      await _addImages(images, StudyMaterialKind.image);
    } catch (_) {
      _showMessage('Could not open your photos. Please try again.');
    }
  }

  /// Takes a single photo with the camera.
  Future<void> _takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return; // cancelled
      await _addImages(<XFile>[photo], StudyMaterialKind.photo);
    } catch (_) {
      _showMessage('Could not open the camera. Please try again.');
    }
  }

  /// Reads the picked images and adds them to the material list.
  Future<void> _addImages(List<XFile> images, StudyMaterialKind kind) async {
    final added = <StudyMaterialItem>[];
    String? problem;

    for (final image in images) {
      if (added.length >= _maxFilesPerPick) {
        problem = 'You can add up to $_maxFilesPerPick images at a time.';
        break;
      }

      final name = _imageName(image);
      try {
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) {
          problem = 'Could not read "$name". Please try another image.';
          continue;
        }
        if (bytes.length > _maxFileBytes) {
          problem =
              '"$name" is larger than 20 MB. Please choose a smaller image.';
          continue;
        }
        added.add(
          StudyMaterialItem(
            name: name,
            kind: kind,
            sizeBytes: bytes.length,
            bytes: bytes,
          ),
        );
      } catch (_) {
        problem = 'Could not read "$name". Please try another image.';
      }
    }

    if (added.isNotEmpty) {
      setState(() {
        _material.addAll(added);
        _processingResult = null;
      });
    }
    _showMessage(
      problem ??
          'Added ${added.length} ${added.length == 1 ? 'image' : 'images'}.',
    );
  }

  /// Resolves a usable display name for a picked image.
  String _imageName(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) return name;
    final path = file.path.trim();
    if (path.isNotEmpty) return path.split('/').last;
    return 'image.jpg';
  }

  /// True when [fileName] ends with one of the [allowed] extensions.
  bool _hasExtension(String fileName, List<String> allowed) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return false;
    return allowed.contains(fileName.substring(dot + 1).toLowerCase());
  }

  void _removeMaterial(int index) {
    setState(() {
      _material.removeAt(index);
      _processingResult = null;
    });
  }

  Future<void> _generateWithoutMaterial() async {
    if (_isProcessing) return;
    await _generateCourse();
  }

  /// Processes the material, asks the server-side AI to build the course, then
  /// shows the Course Preview. Nothing is saved yet.
  Future<void> _generateCourse() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _processingResult = null;
      _progressLabel = 'Preparing your study material...';
    });

    GeneratedCourse? generated;

    try {
      // Topic-only generation is supported and should work without uploads.
      if (_material.isEmpty) {
        setState(() => _progressLabel = 'Generating your course...');
        generated = await _courseAiService.generateCourse(
          course: widget.course,
          material: const <ProcessedMaterial>[],
        );
      } else {
        final result = await _materialService.process(_material);
        if (!mounted) return;

        setState(() => _processingResult = result);

        if (!result.hasUsableMaterial) {
          _showMessage(
            'Your uploaded reference material could not be read, so we will generate the course from the topic instead.',
          );
          setState(() => _progressLabel = 'Generating your course...');
          generated = await _courseAiService.generateCourse(
            course: widget.course,
            material: const <ProcessedMaterial>[],
          );
        } else {
          setState(() => _progressLabel = 'Generating your course...');
          generated = await _courseAiService.generateCourse(
            course: widget.course,
            material: result.items,
          );
        }
      }
    } on CourseAiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progressLabel = 'Preparing your study material...';
        });
      }
    }

    final course = generated;
    if (!mounted || course == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoursePreviewScreen(
          course: course,
          onRegenerate: _regenerateCourse,
        ),
      ),
    );
  }

  /// Re-runs generation for the "Regenerate" button on the preview screen.
  Future<GeneratedCourse?> _regenerateCourse() async {
    try {
      if (_material.isEmpty) {
        return await _courseAiService.generateCourse(
          course: widget.course,
          material: const <ProcessedMaterial>[],
        );
      }

      final result = await _materialService.process(_material);
      if (!mounted) return null;

      if (!result.hasUsableMaterial) {
        _showMessage(
          'Your uploaded reference material could not be read, so we are generating from the topic instead.',
        );
        return await _courseAiService.generateCourse(
          course: widget.course,
          material: const <ProcessedMaterial>[],
        );
      }

      return await _courseAiService.generateCourse(
        course: widget.course,
        material: result.items,
      );
    } on CourseAiException catch (e) {
      if (mounted) {
        _showMessage(e.message);
      }
      return null;
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reference Material (Optional)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCourseSummary(context),
            const SizedBox(height: 20),
            Text(
              'Add Reference Material (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload notes, PDFs, documents, or images to personalize your course. You can also skip this step.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            _buildMaterialTiles(),
            const SizedBox(height: 20),
            _buildTypedTextSection(),
            const SizedBox(height: 20),
            _buildSelectedMaterial(),
            if (_processingResult != null) ...[
              const SizedBox(height: 20),
              _buildProcessingStatus(context, _processingResult!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _generateWithoutMaterial,
                    icon: const Icon(Icons.skip_next_outlined),
                    label: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _generateCourse,
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_progressLabel),
                              ],
                            )
                          : const Text('Generate Course'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.course.subtitle),
            if ((widget.course.learningGoal ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Goal: ${widget.course.learningGoal}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialTiles() {
    final kinds = [
      StudyMaterialKind.pdf,
      StudyMaterialKind.document,
      StudyMaterialKind.presentation,
      StudyMaterialKind.image,
      StudyMaterialKind.photo,
      StudyMaterialKind.text,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kinds.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final kind = kinds[index];
        return InkWell(
          onTap: () => _onMaterialTap(kind),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_kindIcon(kind), color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(kind.label),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _kindIcon(StudyMaterialKind kind) {
    switch (kind) {
      case StudyMaterialKind.pdf:
        return Icons.picture_as_pdf;
      case StudyMaterialKind.document:
        return Icons.description;
      case StudyMaterialKind.presentation:
        return Icons.slideshow;
      case StudyMaterialKind.image:
        return Icons.image;
      case StudyMaterialKind.photo:
        return Icons.photo_camera;
      case StudyMaterialKind.text:
        return Icons.text_fields;
    }
  }

  Widget _buildTypedTextSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste notes'),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste the lesson notes or textbook text here...',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _addTypedText,
                icon: const Icon(Icons.add),
                label: const Text('Add notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMaterial() {
    if (_material.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No reference material added yet. You can continue without uploading anything.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected material'),
            const SizedBox(height: 12),
            ...List<Widget>.generate(_material.length, (index) {
              final item = _material[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name),
                        const SizedBox(height: 2),
                        Text(
                          item.kind.label,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeMaterial(index),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStatus(
    BuildContext context,
    MaterialProcessingResult result,
  ) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.summaryMessage,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...result.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• ${item.name}: ${item.statusLabel}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
