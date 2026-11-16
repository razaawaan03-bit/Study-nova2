import 'package:flutter/material.dart';
import 'package:studynova/models/study_scan_model.dart';

class StudyQuizScreen extends StatefulWidget {
  final String topic;
  final List<dynamic> quizData;
  final VoidCallback? onComplete;

  const StudyQuizScreen({
    super.key,
    required this.topic,
    required this.quizData,
    this.onComplete,
  });

  @override
  State<StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<StudyQuizScreen> {
  late List<QuizQuestion> questions;
  int currentQuestionIndex = 0;
  Map<int, String> userAnswers = {};
  bool showResults = false;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
  }

  void _initializeQuestions() {
    questions = [];
    for (var item in widget.quizData) {
      if (item is QuizQuestion) {
        questions.add(item);
      } else if (item is Map<String, dynamic>) {
        questions.add(QuizQuestion.fromJson(item));
      }
    }

    if (questions.isEmpty) {
      questions = [
        QuizQuestion(
          id: '1',
          question: 'What is the main topic of this material?',
          options: [widget.topic, 'Related concept', 'Different topic'],
          correctAnswer: widget.topic,
          explanation: 'This was the main topic.',
          type: 'multiple_choice',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showResults) {
      return _buildResultsView(context);
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No quiz questions available')),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${currentQuestionIndex + 1}/${questions.length}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              minHeight: 6,
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question
                  Text(
                    currentQuestion.question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Options
                  if (currentQuestion.type == 'multiple_choice' ||
                      currentQuestion.type == 'true_false')
                    ...List.generate(currentQuestion.options.length, (index) {
                      final option = currentQuestion.options[index];
                      final isSelected =
                          userAnswers[currentQuestionIndex] == option;
                      final isCorrect = option == currentQuestion.correctAnswer;
                      final showAnswer = userAnswers.containsKey(
                        currentQuestionIndex,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          child: InkWell(
                            onTap: showAnswer
                                ? null
                                : () {
                                    setState(() {
                                      userAnswers[currentQuestionIndex] =
                                          option;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: showAnswer
                                    ? (isCorrect
                                          ? Colors.green.shade50
                                          : (isSelected
                                                ? Colors.red.shade50
                                                : Colors.grey.shade50))
                                    : (isSelected
                                          ? Colors.blue.shade50
                                          : Colors.grey.shade50),
                                border: Border.all(
                                  color: showAnswer
                                      ? (isCorrect
                                            ? Colors.green.shade300
                                            : (isSelected
                                                  ? Colors.red.shade300
                                                  : Colors.grey.shade300))
                                      : (isSelected
                                            ? Colors.blue.shade300
                                            : Colors.grey.shade300),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: showAnswer
                                          ? (isCorrect
                                                ? Colors.green
                                                : (isSelected
                                                      ? Colors.red
                                                      : Colors.grey))
                                          : (isSelected
                                                ? Colors.blue
                                                : Colors.grey.shade400),
                                    ),
                                    child: showAnswer && isCorrect
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : showAnswer && isSelected
                                        ? const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            userAnswers[currentQuestionIndex] = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Type your answer...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                    ),

                  // Explanation (if answered)
                  if (userAnswers.containsKey(currentQuestionIndex))
                    Container(
                      margin: const EdgeInsets.only(top: 24),
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
                            '📝 Explanation:',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentQuestion.explanation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Navigation buttons
                  Row(
                    children: [
                      if (currentQuestionIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                currentQuestionIndex--;
                              });
                            },
                            child: const Text('Previous'),
                          ),
                        ),
                      if (currentQuestionIndex > 0) const SizedBox(width: 12),
                      if (currentQuestionIndex < questions.length - 1)
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                userAnswers.containsKey(currentQuestionIndex)
                                ? () {
                                    setState(() {
                                      currentQuestionIndex++;
                                    });
                                  }
                                : null,
                            child: const Text('Next'),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showResults = true;
                              });
                            },
                            child: const Text('Finish Quiz'),
                          ),
                        ),
                    ],
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

  Widget _buildResultsView(BuildContext context) {
    int correctAnswers = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i].correctAnswer) {
        correctAnswers++;
      }
    }
    final percentage = ((correctAnswers / questions.length) * 100).toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score display
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: percentage >= 70
                          ? Colors.green.shade100
                          : percentage >= 50
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                    ),
                    child: Center(
                      child: Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: percentage >= 70
                                  ? Colors.green.shade700
                                  : percentage >= 50
                                  ? Colors.orange.shade700
                                  : Colors.red.shade700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$correctAnswers out of ${questions.length} correct',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    percentage >= 70
                        ? 'Great work! 🎉'
                        : percentage >= 50
                        ? 'Good effort! Keep learning.'
                        : 'Review the material and try again.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Detailed results
            Text(
              'Detailed Results',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(questions.length, (index) {
              final question = questions[index];
              final userAnswer = userAnswers[index];
              final isCorrect = userAnswer == question.correctAnswer;

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
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Question ${index + 1}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.question,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your answer: ${userAnswer ?? 'Not answered'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isCorrect)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Correct answer: ${question.correctAnswer}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),

            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Back to Study'),
            ),
          ],
        ),
      ),
    );
  }
}
