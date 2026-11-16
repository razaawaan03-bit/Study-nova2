import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/ai_study_service.dart';
import 'study_explanation_screen.dart';

class StudyAnalysisScreen extends StatefulWidget {
  /// Raw bytes of the selected image.
  ///
  /// Bytes are used instead of a `File` so this screen works on every
  /// platform, including Flutter Web where `dart:io` / `Image.file` are not
  /// supported.
  final Uint8List imageBytes;

  /// Original file name of the image, used to detect its type for the AI
  /// request.
  final String fileName;

  const StudyAnalysisScreen({
    super.key,
    required this.imageBytes,
    this.fileName = 'study_image.jpg',
  });

  @override
  State<StudyAnalysisScreen> createState() => _StudyAnalysisScreenState();
}

class _StudyAnalysisScreenState extends State<StudyAnalysisScreen> {
  bool _isAnalyzing = false;
  String? _error;
  String _selectedLevel = 'normal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review & Analyze'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview (Image.memory works on Android, iOS, desktop & Web)
            Container(
              height: 300,
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: _buildImagePreview(),
            ),
            const SizedBox(height: 24),

            // Content section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Explanation level selector
                  Text(
                    'Choose Explanation Level',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLevelSelector(context),
                  const SizedBox(height: 24),

                  // Info about next steps
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What will happen next:',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoStep(context, '1', 'AI analyzes your image'),
                        _buildInfoStep(
                          context,
                          '2',
                          'Detailed explanation is generated',
                        ),
                        _buildInfoStep(context, '3', 'Mind map is created'),
                        _buildInfoStep(
                          context,
                          '4',
                          'Quiz questions are prepared',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error display
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Analyze button
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _handleAnalyze,
                    icon: _isAnalyzing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isAnalyzing ? 'Analyzing...' : 'Analyze Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Retake button
                  OutlinedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.close),
                    label: const Text('Retake / Choose Another'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Renders the picked image from memory and degrades gracefully when the
  /// bytes are missing or cannot be decoded.
  Widget _buildImagePreview() {
    if (widget.imageBytes.isEmpty) {
      return _buildPreviewError();
    }

    return Image.memory(
      widget.imageBytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => _buildPreviewError(),
    );
  }

  Widget _buildPreviewError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 48, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            'Image preview unavailable',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector(BuildContext context) {
    final levels = [
      ('easy', 'Easy', 'Simple words, basics'),
      ('normal', 'Normal', 'Balanced detail'),
      ('detailed', 'Detailed', 'In depth'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: levels.map((level) {
          final isSelected = _selectedLevel == level.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              child: InkWell(
                onTap: () => setState(() => _selectedLevel = level.$1),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade600
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.$2,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.$3,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAnalyze() async {
    // Reset error
    setState(() => _error = null);

    // Validate the image bytes before doing any work
    if (widget.imageBytes.isEmpty) {
      setState(
        () => _error =
            'The selected image is empty or could not be read. '
            'Please choose another image.',
      );
      return;
    }

    // Check image size
    final fileSize = widget.imageBytes.lengthInBytes;
    if (fileSize > 20 * 1024 * 1024) {
      setState(
        () => _error =
            'Image is too large (max 20MB). Please choose a smaller image.',
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // No Gemini key is used or needed here. The analysis is produced by the
      // `study-from-photo` Supabase Edge Function, which reads the key from its
      // own server-side secret, so the key never reaches the device.
      final aiService = AIStudyService();

      // Analyze image
      final analysisResult = await aiService.analyzeImage(
        widget.imageBytes,
        fileName: widget.fileName,
        explanationLevel: _selectedLevel,
      );

      if (!mounted) return;

      // Navigate to explanation screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudyExplanationScreen(
            imageBytes: widget.imageBytes,
            fileName: widget.fileName,
            analysisData: analysisResult,
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } catch (e) {
      // Any other failure (a type or state error deep in the pipeline) must
      // still leave the student on this screen with a retry, never crash.
      debugPrint('StudyAnalysisScreen: unexpected analysis failure: $e');
      if (!mounted) return;
      setState(
        () => _error =
            'Something went wrong while analysing your photo. Please try '
            'again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }
}
