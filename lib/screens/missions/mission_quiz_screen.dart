import 'package:flutter/material.dart';

import '../../models/lab_model.dart';
import '../../models/mission_model.dart';
import '../../services/lab_service.dart';
import '../../services/mission_service.dart';
import 'mission_completion_screen.dart';
import 'mission_widgets.dart';

/// Which mission quiz is being run.
enum MissionQuizMode {
  practice('Practice', 'practice'),
  mockTest('Mock Test', 'mock_test'),
  finalChallenge('Final Challenge', 'final_challenge');

  const MissionQuizMode(this.label, this.storageValue);

  final String label;
  final String storageValue;

  int get questionCount => switch (this) {
    MissionQuizMode.practice => 5,
    MissionQuizMode.mockTest => 10,
    MissionQuizMode.finalChallenge => 15,
  };
}

/// One question in a mission quiz, always taken from existing Study Nova
/// content and tagged with the mission topic it belongs to.
class MissionQuestion {
  const MissionQuestion({
    required this.question,
    required this.topic,
    required this.source,
    this.labId,
  });

  final QuizQuestion question;
  final String topic;

  /// e.g. "SST Fundamentals" — where the question really comes from.
  final String source;
  final String? labId;
}

/// Runs a practice set, a mock test or the Final Challenge of a mission.
///
/// Questions are never invented: they are collected from the quiz questions of
/// the Study Nova Labs this mission links to. If the mission has no Lab quiz
/// content, the screen says so instead of faking a test.
class MissionQuizScreen extends StatefulWidget {
  const MissionQuizScreen({
    super.key,
    required this.missionId,
    required this.mode,
    this.topic,
  });

  final String? missionId;
  final MissionQuizMode mode;

  /// Restricts practice questions to one topic.
  final String? topic;

  @override
  State<MissionQuizScreen> createState() => _MissionQuizScreenState();
}

class _MissionQuizScreenState extends State<MissionQuizScreen> {
  final MissionService _missionService = MissionService.instance;
  final LabService _labService = LabService.instance;

  List<MissionQuestion> _questions = const [];
  final Map<int, String> _answers = <int, String>{};
  int _currentIndex = 0;
  bool _showResults = false;
  bool _recording = false;

  MissionModel? get _mission => _missionService.byId(widget.missionId);

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  /// Collects real questions from every Lab the mission links to, keeping the
  /// mission topic each Lab was matched for.
  List<MissionQuestion> _buildQuestions() {
    final mission = _mission;
    if (mission == null) return const [];

    final topicByLab = <String, String>{};
    for (final task in mission.allTasks) {
      if (!task.hasLab || task.labId == null) continue;
      topicByLab.putIfAbsent(task.labId!, () => task.topic);
    }

    final questions = <MissionQuestion>[];
    final seen = <String>{};

    for (final entry in topicByLab.entries) {
      final lab = _labService.labById(entry.key);
      if (lab == null) continue;
      for (final question in lab.quizQuestions) {
        final key = '${lab.id}-${question.id}';
        if (!seen.add(key)) continue;
        questions.add(
          MissionQuestion(
            question: question,
            topic: entry.value.isEmpty ? lab.title : entry.value,
            source: lab.title,
            labId: lab.id,
          ),
        );
      }
    }

    final filtered = widget.topic == null || widget.topic!.isEmpty
        ? questions
        : questions.where((item) => item.topic == widget.topic).toList();

    final pool = filtered.isEmpty ? questions : filtered;

    // Spread the questions across topics so a mock test is not one lab only.
    final byTopic = <String, List<MissionQuestion>>{};
    for (final item in pool) {
      byTopic.putIfAbsent(item.topic, () => <MissionQuestion>[]).add(item);
    }

    final spread = <MissionQuestion>[];
    var added = true;
    var round = 0;
    while (spread.length < pool.length && added) {
      added = false;
      for (final topic in byTopic.keys.toList()) {
        final list = byTopic[topic]!;
        if (round < list.length) {
          spread.add(list[round]);
          added = true;
          if (spread.length >= widget.mode.questionCount) break;
        }
      }
      round++;
    }

    return spread.take(widget.mode.questionCount).toList();
  }

  int get _correctCount {
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].question.correctAnswer) correct++;
    }
    return correct;
  }

  int get _percentage => _questions.isEmpty
      ? 0
      : ((_correctCount / _questions.length) * 100).round();

  bool _isAnswered(int index) => _answers.containsKey(index);

  Future<void> _finish() async {
    setState(() => _showResults = true);

    if (_recording) return;
    _recording = true;

    // Per-topic performance, used for the revision suggestions.
    final topicTotals = <String, List<int>>{};
    for (var i = 0; i < _questions.length; i++) {
      final item = _questions[i];
      final bucket = topicTotals.putIfAbsent(item.topic, () => <int>[0, 0]);
      bucket[1]++;
      if (_answers[i] == item.question.correctAnswer) bucket[0]++;
    }

    final now = DateTime.now();
    final results = topicTotals.entries
        .map(
          (entry) => MissionTopicResult(
            topic: entry.key,
            correct: entry.value[0],
            total: entry.value[1],
            attemptedAt: now,
          ),
        )
        .toList();

    final mission = _mission;
    if (mission != null) {
      await _missionService.recordQuizRun(
        mission.id,
        results: results,
        isFinalChallenge: widget.mode == MissionQuizMode.finalChallenge,
        percentage: _percentage,
      );

      // The quiz the student just finished also completes its own task.
      for (final task in mission.allTasks) {
        final matchesMode = widget.mode == MissionQuizMode.finalChallenge
            ? task.type == MissionTaskType.finalChallenge
            : task.type == MissionTaskType.practice ||
                  task.type == MissionTaskType.mockTest ||
                  task.type == MissionTaskType.quiz;
        if (matchesMode && task.dayNumber == _dayForQuiz(mission)) {
          await _missionService.setTaskCompleted(mission.id, task.id);
        }
      }
    }
  }

  /// The day whose tasks this quiz belongs to: the suggested day.
  int _dayForQuiz(MissionModel mission) {
    final day = mission.dayByNumber(mission.suggestedDay);
    if (day != null && widget.topic != null) {
      if (day.focusTopic == widget.topic) return day.dayNumber;
    }
    return mission.suggestedDay;
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
    final mission = _mission;
    if (mission == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode.label), centerTitle: true),
        body: const Center(child: Text('This mission could not be found.')),
      );
    }

    if (_questions.isEmpty) {
      return _buildNoQuestions(mission);
    }

    if (_showResults) return _buildResults(mission);

    final item = _questions[_currentIndex];
    final answered = _isAnswered(_currentIndex);
    final isLast = _currentIndex == _questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.mode.label} • ${_currentIndex + 1}/${_questions.length}',
        ),
        centerTitle: true,
      ),
      body: MissionPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: MissionProgressBar(
                percent: ((_currentIndex + 1) / _questions.length * 100)
                    .round(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  MissionBadge(
                    label: item.topic.isEmpty ? item.source : item.topic,
                    color: kMissionAccent,
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.question.question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...item.question.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOption(item, option, answered),
                    ),
                  ),
                  if (answered) ...[
                    const SizedBox(height: 8),
                    _buildExplanation(item),
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

  Widget _buildOption(MissionQuestion item, String option, bool answered) {
    final isSelected = _answers[_currentIndex] == option;
    final isCorrect = option == item.question.correctAnswer;

    late Color background;
    late Color border;
    late Color marker;
    late Widget markerChild;

    if (!answered) {
      background = isSelected
          ? kMissionPrimary.withValues(alpha: 0.08)
          : Colors.white;
      border = isSelected ? kMissionPrimary : Colors.grey.shade300;
      marker = isSelected ? kMissionPrimary : Colors.grey.shade200;
      markerChild = Text(
        String.fromCharCode(65 + item.question.options.indexOf(option)),
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
        onTap: answered
            ? null
            : () => setState(() => _answers[_currentIndex] = option),
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

  Widget _buildExplanation(MissionQuestion item) {
    final wasCorrect = _answers[_currentIndex] == item.question.correctAnswer;
    final color = wasCorrect ? Colors.green : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: color.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                wasCorrect ? 'Correct' : 'Explanation',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          if (!wasCorrect) ...[
            const SizedBox(height: 6),
            Text(
              'Correct answer: ${item.question.correctAnswer}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
          ],
          if (item.question.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.question.explanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'From ${item.source}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
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
              label: Text(isLast ? 'Finish' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQuestions(MissionModel mission) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.label), centerTitle: true),
      body: MissionPage(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.quiz_outlined, size: 56, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No quiz questions found for this mission yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mission questions come from Study Nova Labs. Open a Lab that '
                  'matches this mission, study a lesson, then come back — or '
                  'create a course with quizzes from the Course Maker.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/labs'),
                  icon: const Icon(Icons.science),
                  label: const Text('Open Study Nova Labs'),
                ),
                const SizedBox(height: 8),
                Text(
                  '${mission.title} • ${mission.completedRequiredTaskCount}/'
                  '${mission.requiredTaskCount} required tasks done',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(MissionModel mission) {
    final questions = _questions;
    final correct = _correctCount;
    final percent = _percentage;
    final scoreColor = percent >= 70
        ? Colors.green
        : percent >= 50
        ? Colors.orange
        : Colors.red;

    // Topic performance, straight from the answers the student gave.
    final topicTotals = <String, List<int>>{};
    for (var i = 0; i < questions.length; i++) {
      final bucket = topicTotals.putIfAbsent(
        questions[i].topic,
        () => <int>[0, 0],
      );
      bucket[1]++;
      if (_answers[i] == questions[i].question.correctAnswer) bucket[0]++;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Results'), centerTitle: true),
      body: MissionPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
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
                const SizedBox(height: 6),
                Text(
                  widget.mode.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (topicTotals.isNotEmpty) ...[
              const MissionSectionHeader(
                title: 'Topic performance',
                icon: Icons.insights,
              ),
              ...topicTotals.entries.map((entry) {
                final topicPercent = entry.value[1] <= 0
                    ? 0
                    : ((entry.value[0] / entry.value[1]) * 100).round();
                final color = topicPercent >= 70
                    ? Colors.green
                    : topicPercent >= 50
                    ? Colors.orange
                    : Colors.red;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      MissionProgressBar(
                        percent: topicPercent,
                        color: color,
                        height: 6,
                      ),
                    ],
                  ),
                );
              }),
              if (mission.revisionSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.replay, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Recommended revision: ${mission.revisionSuggestions.map((r) => r.topic).join(', ')}.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            const MissionSectionHeader(
              title: 'Review',
              icon: Icons.fact_check_outlined,
            ),
            ...List.generate(questions.length, (index) {
              final item = questions[index];
              final answer = _answers[index];
              final isCorrect = answer == item.question.correctAnswer;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
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
                            item.question.question,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                        'Correct answer: ${item.question.correctAnswer}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'From ${item.source}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
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
                label: const Text('Try again'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final updated = _mission;
                  if (updated != null && updated.isCompleted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            MissionCompletionScreen(missionId: updated.id),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  widget.mode == MissionQuizMode.finalChallenge
                      ? 'Back to mission'
                      : 'Back to today',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
