import 'package:flutter/material.dart';
import 'package:studynova/models/study_scan_model.dart';
import 'package:studynova/widgets/mind_map_widget.dart';
import 'package:intl/intl.dart';
import 'study_quiz_screen.dart';

class StudyLibraryDetailScreen extends StatefulWidget {
  final StudyScanModel studyScan;
  final int initialTab;

  const StudyLibraryDetailScreen({
    super.key,
    required this.studyScan,
    this.initialTab = 0,
  });

  @override
  State<StudyLibraryDetailScreen> createState() =>
      _StudyLibraryDetailScreenState();
}

class _StudyLibraryDetailScreenState extends State<StudyLibraryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
    final date = widget.studyScan.createdAt ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studyScan.topic),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explanation', icon: Icon(Icons.description)),
            Tab(text: 'Mind Map', icon: Icon(Icons.account_tree)),
            Tab(text: 'Quiz', icon: Icon(Icons.quiz)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Explanation tab
          _buildExplanationTab(context, dateFormat, date),

          // Mind Map tab
          _buildMindMapTab(context),

          // Quiz tab
          _buildQuizTab(context),
        ],
      ),
    );
  }

  Widget _buildExplanationTab(
    BuildContext context,
    DateFormat dateFormat,
    DateTime date,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta info
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
                Row(
                  children: [
                    Icon(Icons.subject, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      widget.studyScan.subject,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.language, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      _getLevelLabel(widget.studyScan.explanationLevel),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Image
          if (widget.studyScan.imageUrl != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original Image',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.studyScan.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Explanation
          Text(
            '📚 Explanation',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            widget.studyScan.explanation,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),

          // Key Points
          if (widget.studyScan.keyPoints.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 Key Points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.studyScan.keyPoints.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          if (widget.studyScan.keyPoints.isNotEmpty) const SizedBox(height: 24),

          // Important Concepts
          if (widget.studyScan.importantConcepts.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Important Concepts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.studyScan.importantConcepts.map(
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
                ),
              ],
            ),

          if (widget.studyScan.importantConcepts.isNotEmpty)
            const SizedBox(height: 24),

          // Common Mistakes
          if (widget.studyScan.commonMistakes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Common Mistakes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.studyScan.commonMistakes.map(
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMindMapTab(BuildContext context) {
    if (widget.studyScan.mindMapData.isEmpty) {
      return Center(
        child: Text(
          'No mind map data available',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return MindMapWidget(
      mindMapData: widget.studyScan.mindMapData,
      topic: widget.studyScan.topic,
    );
  }

  Widget _buildQuizTab(BuildContext context) {
    if (widget.studyScan.quizData.isEmpty) {
      return Center(
        child: Text(
          'No quiz data available',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return StudyQuizScreen(
      topic: widget.studyScan.topic,
      quizData: widget.studyScan.quizData,
    );
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'easy':
        return 'Easy - Simple & Basic';
      case 'detailed':
        return 'Detailed - In Depth';
      default:
        return 'Normal - Balanced';
    }
  }
}
