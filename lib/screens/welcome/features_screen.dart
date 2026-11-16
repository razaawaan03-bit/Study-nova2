import 'package:flutter/material.dart';
// removed unused import

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What is Study Nova?'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Study Nova',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create Smart Courses with AI',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Features Section
            Text(
              'Key Features',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Feature 1
            _buildFeatureCard(
              context,
              icon: Icons.smart_toy,
              title: 'AI-Powered Course Creation',
              description:
                  'Let artificial intelligence help you create engaging and structured courses in minutes, not hours.',
            ),
            const SizedBox(height: 12),

            // Feature 2
            _buildFeatureCard(
              context,
              icon: Icons.book,
              title: 'Smart Learning Paths',
              description:
                  'Get personalized learning recommendations based on your progress and learning style.',
            ),
            const SizedBox(height: 12),

            // Feature 3
            _buildFeatureCard(
              context,
              icon: Icons.quiz,
              title: 'Interactive Quizzes',
              description:
                  'Test your knowledge with AI-generated quizzes that adapt to your skill level.',
            ),
            const SizedBox(height: 12),

            // Feature 4
            _buildFeatureCard(
              context,
              icon: Icons.bar_chart,
              title: 'Progress Tracking',
              description:
                  'Monitor your learning journey with detailed analytics and performance insights.',
            ),
            const SizedBox(height: 12),

            // Feature 5
            _buildFeatureCard(
              context,
              icon: Icons.group,
              title: 'Community Learning',
              description:
                  'Connect with other learners, share courses, and collaborate on educational content.',
            ),
            const SizedBox(height: 12),

            // Feature 6
            _buildFeatureCard(
              context,
              icon: Icons.emoji_events,
              title: 'Earn Certificates',
              description:
                  'Complete courses and earn verifiable certificates to showcase your achievements.',
            ),
            const SizedBox(height: 40),

            // How it Works Section
            Text(
              'How It Works',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildStepCard(context, 1, 'Sign Up', 'Create your free account'),
            const SizedBox(height: 12),

            _buildStepCard(
              context,
              2,
              'Create Course',
              'Let AI help you build a course',
            ),
            const SizedBox(height: 12),

            _buildStepCard(
              context,
              3,
              'Start Learning',
              'Share with others and begin learning',
            ),
            const SizedBox(height: 12),

            _buildStepCard(
              context,
              4,
              'Grow & Share',
              'Track progress and earn certificates',
            ),
            const SizedBox(height: 40),

            // Call to action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Get Started Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    int step,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
