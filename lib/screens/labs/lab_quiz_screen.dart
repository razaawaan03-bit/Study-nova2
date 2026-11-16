import 'package:flutter/material.dart';

import '../../models/lab_model.dart';
import '../../services/lab_service.dart';
import 'lab_widgets.dart';

/// Runs the quiz that ships with a Lab.
///
/// Questions come straight from [LabModel.quizQuestions] in the bundled Lab
/// content — nothing is generated here. Each question is answered once, the
/// explanation is revealed straight away, and the finished run is stored with
/// [LabService.recordQuizAttempt] so the Lab detail screen can show a best
/// score.
class LabQuizScreen extends StatefulWidget {
  const LabQuizScreen({super.key, required this.labId});

  final String? labId;

  @override
  State<LabQuizScreen> createState() => _LabQuizScreenState();
}

class _LabQuizScreenState extends State<LabQuizScreen> {
  final LabService _labService = LabService.instance;

  int _currentIndex = 0;
  final Map<int, String> _answers = <int, String>{};
  bool _showResults = false;

  LabModel? get _lab => _labService.labById(widget.labId);

  List<QuizQuestion> get _questions =>
      _lab?.quizQuestions ?? const <QuizQuestion>[];

  bool _isAnswered(int index) => _answers.containsKey(index);

  int get _correctCount {
    var correct = 0;
    final questions = _questions;
    for (var i = 0; i < questions.length; i++) {
      if (_answers[i] == questions[i].correctAnswer) correct++;
    }
    return correct;
  }

  int get _percentage {
    final total = _questions.length;
    if (total == 0) return 0;
    return ((_correctCount / total) * 100).round();
  }

  void _select(String option) {
    if (_isAnswered(_currentIndex)) return;
    setState(() {
      _answers[_currentIndex] = option;
    });
  }

  Future<void> _finish() async {
    final lab = _lab;
    if (lab == null) return;
    setState(() => _showResults = true);
    await _labService.recordQuizAttempt(
      lab.id,
      score: _correctCount,
      totalQuestions: _questions.length,
    );
  }

  void _restart() {
    setState(() {
      _answers.clear();
      _currentIndex = 0;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lab = _lab;

    if (lab == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz'), centerTitle: true),
        body: const Center(child: Text('This Lab could not be found.')),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('${lab.title} Quiz'), centerTitle: true),
        body: LabPage(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'This Lab has no quiz questions yet.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      );
    }

    if (_showResults) return _buildResults(lab);

    final question = _questions[_currentIndex];
    final accent = labCategoryColor(lab.category);
    final answered = _isAnswered(_currentIndex);
    final isLast = _currentIndex == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
        centerTitle: true,
      ),
      body: LabPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: LabProgressBar(
                percent: ((_currentIndex + 1) / _questions.length * 100)
                    .round(),
                color: accent,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text(
                    lab.title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Answer options
                  ...question.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOption(question, option, answered, accent),
                    ),
                  ),

                  // Explanation, shown once the question is answered
                  if (answered) ...[
                    const SizedBox(height: 12),
                    _buildExplanation(question),
                  ],
                ],
              ),
            ),
            _buildNavBar(answered: answered, isLast: isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    QuizQuestion question,
    String option,
    bool answered,
    Color accent,
  ) {
    final isSelected = _answers[_currentIndex] == option;
    final isCorrect = option == question.correctAnswer;

    Color background;
    Color border;
    Color marker;
    Widget markerChild;

    if (!answered) {
      background = isSelected ? accent.withValues(alpha: 0.08) : Colors.white;
      border = isSelected ? accent : Colors.grey.shade300;
      marker = isSelected ? accent : Colors.grey.shade200;
      markerChild = Text(
        String.fromCharCode(65 + question.options.indexOf(option)),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      );
    } else if (isCorrect) {
      background = Colors.green.shade50;
      border = Colors.green.shade400;
      marker = Colors.green;
      markerChild = const Icon(Icons.check, color: Colors.white, size: 14);
    } else if (isSelected) {
      background = Colors.red.shade50;
      border = Colors.red.shade400;
      marker = Colors.red;
      markerChild = const Icon(Icons.close, color: Colors.white, size: 14);
    } else {
      background = Colors.white;
      border = Colors.grey.shade300;
      marker = Colors.grey.shade200;
      markerChild = const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: answered ? null : () => _select(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marker,
                ),
                child: markerChild,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(QuizQuestion question) {
    final wasCorrect = _answers[_currentIndex] == question.correctAnswer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (wasCorrect ? Colors.green : Colors.blue).shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (wasCorrect ? Colors.green : Colors.blue).shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: wasCorrect
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                wasCorrect ? 'Correct' : 'Explanation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: wasCorrect
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                ),
              ),
            ],
          ),
          if (!wasCorrect) ...[
            const SizedBox(height: 6),
            Text(
              'Correct answer: ${question.correctAnswer}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
          ],
          if (question.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              question.explanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavBar({required bool answered, required bool isLast}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentIndex == 0
                  ? null
                  : () => setState(() => _currentIndex--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: answered
                  ? () {
                      if (isLast) {
                        _finish();
                      } else {
                        setState(() => _currentIndex++);
                      }
                    }
                  : null,
              icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
              label: Text(isLast ? 'Finish Quiz' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(LabModel lab) {
    final questions = _questions;
    final correct = _correctCount;
    final percent = _percentage;
    final stats = _labService.statsFor(lab.id);
    final scoreColor = percent >= 70
        ? Colors.green
        : percent >= 50
        ? Colors.orange
        : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results'), centerTitle: true),
      body: LabPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // Score
            Column(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.shade100,
                  ),
                  child: Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$correct of ${questions.length} correct',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  percent >= 70
                      ? 'Great work. You know this Lab well.'
                      : percent >= 50
                      ? 'Good effort. Review the lessons and try again.'
                      : 'Revisit the lessons, then take the quiz again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                if (stats.attemptCount > 0) ...[
                  const SizedBox(height: 12),
                  LabBadge(
                    label:
                        'Best ${stats.bestScore}/${stats.bestPercentage}% · '
                        '${stats.attemptCount} attempt'
                        '${stats.attemptCount == 1 ? '' : 's'}',
                    color: Colors.blueGrey,
                    icon: Icons.emoji_events_outlined,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),

            Text(
              'Review',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...List.generate(questions.length, (index) {
              final question = questions[index];
              final answer = _answers[index];
              final isCorrect = answer == question.correctAnswer;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            question.question,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your answer: ${answer ?? 'Not answered'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCorrect
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Correct answer: ${question.correctAnswer}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (question.explanation.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        question.explanation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Quiz'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Lab'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
