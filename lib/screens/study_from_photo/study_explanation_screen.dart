import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:studynova/models/study_scan_model.dart';
import 'package:studynova/services/ai_study_service.dart';
import 'package:studynova/services/study_scan_service.dart';
import 'package:studynova/utils/supabase_availability.dart';
import 'mind_map_screen.dart';
import 'study_quiz_screen.dart';
import 'study_library_screen.dart';

class StudyExplanationScreen extends StatefulWidget {
  /// Raw bytes of the analyzed image.
  ///
  /// Bytes are used instead of a `File` so this screen works on every
  /// platform, including Flutter Web where `dart:io` / `Image.file` are not
  /// supported.
  final Uint8List imageBytes;

  /// Original file name of the image, used when saving it to storage.
  final String fileName;

  final Map<String, dynamic> analysisData;

  const StudyExplanationScreen({
    super.key,
    required this.imageBytes,
    this.fileName = 'study_image.jpg',
    required this.analysisData,
  });

  @override
  State<StudyExplanationScreen> createState() => _StudyExplanationScreenState();
}

class _StudyExplanationScreenState extends State<StudyExplanationScreen> {
  late StudyScanService _studyScanService;
  bool _isSaving = false;
  bool _hasAskedFollowUp = false;
  bool _isAskingFollowUp = false;
  String? _followUpQuestion;
  String? _followUpAnswer;
  String? _followUpError;
  late String _currentExplanation;

  @override
  void initState() {
    super.initState();
    _studyScanService = StudyScanService();
    _currentExplanation = widget.analysisData['explanation'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.analysisData['topic'] ?? 'Unknown';
    final subject = widget.analysisData['subject'] ?? 'General';
    final summary = widget.analysisData['summary'] ?? '';
    final keyPoints = List<String>.from(
      widget.analysisData['key_points'] ?? [],
    );
    final importantConcepts = List<String>.from(
      widget.analysisData['important_concepts'] ?? [],
    );
    final commonMistakes = List<String>.from(
      widget.analysisData['common_mistakes'] ?? [],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Result'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveToLibrary,
            tooltip: 'Save to library',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview (compact)
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 24),

            // Topic header
            Text(
              topic,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subject,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            if (summary.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (summary.isNotEmpty) const SizedBox(height: 24),

            // Explanation section
            _buildSection(
              context,
              title: '📚 Explanation',
              icon: Icons.description,
              content: [
                Text(
                  _currentExplanation,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Important concepts
            if (importantConcepts.isNotEmpty)
              _buildSection(
                context,
                title: '💡 Important Concepts',
                icon: Icons.lightbulb,
                content: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: importantConcepts
                        .map(
                          (concept) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '• $concept',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            if (importantConcepts.isNotEmpty) const SizedBox(height: 20),

            // Key points
            if (keyPoints.isNotEmpty)
              _buildSection(
                context,
                title: '📝 Key Points',
                icon: Icons.check_circle,
                content: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: keyPoints
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      '${entry.key + 1}',
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
                                  child: Text(
                                    entry.value,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            if (keyPoints.isNotEmpty) const SizedBox(height: 20),

            // Common mistakes
            if (commonMistakes.isNotEmpty)
              _buildSection(
                context,
                title: '⚠️ Common Mistakes',
                icon: Icons.warning,
                content: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: commonMistakes
                        .map(
                          (mistake) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '• $mistake',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.red.shade700),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            if (commonMistakes.isNotEmpty) const SizedBox(height: 20),

            // Ask follow-up question section
            _buildAskQuestionSection(context),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(context, topic, subject),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...content,
      ],
    );
  }

  Widget _buildAskQuestionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❓ Ask a Question',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => _followUpQuestion = value,
            decoration: InputDecoration(
              hintText: 'Ask a follow-up question about this topic...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _isAskingFollowUp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _hasAskedFollowUp
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            maxLines: 3,
            enabled: !_hasAskedFollowUp && !_isAskingFollowUp,
          ),
          const SizedBox(height: 12),
          if (_followUpError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _followUpError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_followUpAnswer != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Answer:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _followUpAnswer!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasAskedFollowUp || _isAskingFollowUp
                  ? null
                  : () => _askFollowUpQuestion(context),
              child: Text(
                _isAskingFollowUp
                    ? 'Asking...'
                    : _hasAskedFollowUp
                    ? 'Question Sent'
                    : 'Ask AI',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    String topic,
    String subject,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What would you like to do next?',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MindMapScreen(
                topic: topic,
                mindMapData: widget.analysisData['mind_map_data'] ?? {},
              ),
            ),
          ),
          icon: const Icon(Icons.account_tree),
          label: const Text('View Mind Map'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudyQuizScreen(
                topic: topic,
                quizData: widget.analysisData['quiz_questions'] ?? [],
                onComplete: _onQuizComplete,
              ),
            ),
          ),
          icon: const Icon(Icons.quiz),
          label: const Text('Take a Quiz'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveToLibrary,
          icon: _isSaving
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
              : const Icon(Icons.save_alt),
          label: Text(_isSaving ? 'Saving...' : 'Save to Study Library'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _askFollowUpQuestion(BuildContext context) async {
    final question = _followUpQuestion?.trim() ?? '';
    if (question.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a question')));
      return;
    }

    setState(() {
      _hasAskedFollowUp = true;
      _isAskingFollowUp = true;
      _followUpError = null;
    });

    try {
      // Same `study-from-photo` Edge Function as the image analysis, called
      // without an image. No Gemini key is used on the device.
      final answer = await AIStudyService().askFollowUpQuestion(
        topic: widget.analysisData['topic'] ?? 'this material',
        explanation: _currentExplanation,
        question: question,
      );
      if (!mounted) return;
      setState(() => _followUpAnswer = answer);
    } catch (e) {
      debugPrint('StudyExplanationScreen: follow-up question failed: $e');
      if (!mounted) return;
      setState(() {
        // Let the student try again rather than locking the button for good.
        _hasAskedFollowUp = false;
        _followUpError = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Something went wrong. Please try again.';
      });
      return;
    } finally {
      if (mounted) {
        setState(() => _isAskingFollowUp = false);
      }
    }
  }

  /// Renders the analyzed image from memory and degrades gracefully when the
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
          Icon(Icons.broken_image, size: 40, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            'Image preview unavailable',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Keeps the uploaded file name safe for a Supabase Storage path.
  String _safeFileName(String name) {
    final cleaned = name
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'^\.+'), '');

    if (cleaned.isEmpty) {
      return 'study_image.jpg';
    }
    return cleaned;
  }

  Future<void> _saveToLibrary() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Check user authentication. `Supabase.instance` asserts when the
      // client is not initialized, so the lookup goes through the safe helper.
      final user = safeSupabase()?.client.auth.currentUser;
      if (user == null) {
        throw Exception('Please sign in to save this to your Study Library.');
      }

      // Upload image to storage using the bytes we already hold
      // (no filesystem access, so this also works on Flutter Web).
      if (widget.imageBytes.isEmpty) {
        throw Exception('The image is empty and cannot be saved.');
      }

      final imageUrl = await _studyScanService.uploadImage(
        widget.imageBytes,
        _safeFileName(widget.fileName),
      );

      // Create study scan model
      final studyScan = StudyScanModel(
        userId: user.id,
        topic: widget.analysisData['topic'] ?? 'Untitled',
        subject: widget.analysisData['subject'] ?? 'General',
        imageUrl: imageUrl,
        explanation: widget.analysisData['explanation'] ?? '',
        keyPoints: List<String>.from(widget.analysisData['key_points'] ?? []),
        mindMapData: widget.analysisData['mind_map_data'] ?? {},
        quizData:
            (widget.analysisData['quiz_questions'] as List?)
                ?.map(
                  (q) => QuizQuestion(
                    id: q['id'] ?? '',
                    question: q['question'] ?? '',
                    options: List<String>.from(q['options'] ?? []),
                    correctAnswer: q['correct_answer'] ?? '',
                    explanation: q['explanation'] ?? '',
                    type: q['type'] ?? 'multiple_choice',
                  ),
                )
                .toList() ??
            [],
        explanationLevel: widget.analysisData['explanation_level'] ?? 'normal',
        importantConcepts: List<String>.from(
          widget.analysisData['important_concepts'] ?? [],
        ),
        commonMistakes: List<String>.from(
          widget.analysisData['common_mistakes'] ?? [],
        ),
      );

      // Save to database
      await _studyScanService.saveStudyScan(studyScan);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Saved to your Study Library!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to library
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudyLibraryScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this analysis. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onQuizComplete() {
    // Quiz completed - could show stats here
  }
}
