import 'package:flutter/material.dart';
import 'package:studynova/utils/supabase_availability.dart';

/// "About Study Nova" — app information, support contact and the policy pages.
///
/// Launch requirement: Google Play expects a privacy policy and, for many
/// regions, terms of service. The full documents live in the project root
/// (`PRIVACY_POLICY.md` and `TERMS_OF_SERVICE.md`); this screen shows the
/// student-facing summary and the contact address.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Kept in step with `version:` in pubspec.yaml. Changing the pubspec version
  /// for a new release means changing this string too.
  static const String appVersion = '1.0.0';

  /// Replace with a real support address before publishing.
  static const String supportEmail = 'support@studynova.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Study Nova'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: <Widget>[
          Center(
            child: Image.asset(
              'assets/images/study_nova.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, size: 96, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Study Nova',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Center(child: Text('Version $appVersion')),
          const SizedBox(height: 24),
          _Section(
            title: 'What Study Nova does',
            body:
                'Study Nova turns a photo of your study material into a clear '
                'explanation, a mind map and a quiz. It builds courses from your '
                'own PDFs and documents, teaches bundled lessons and quizzes in '
                'Study Nova Labs, and plans your day-by-day study with Missions.',
          ),
          _Section(
            title: 'Your study material stays yours',
            body:
                'Material you analyse is stored in your own account and is only '
                'sent to the AI service to produce your explanation. One account '
                'can never see another account\'s work.',
          ),
          _Section(
            title: 'AI answers can be wrong',
            body:
                'Explanations, mind maps and quizzes are produced by AI. Always '
                'check them against your textbook or teacher before relying on '
                'them.',
          ),
          _Section(
            title: 'Works offline',
            body:
                'Study Nova Labs and your study plan work without an internet '
                'connection. Photo analysis and course creation need a connection.',
          ),
          const SizedBox(height: 8),
          _Section(
            title: 'Privacy Policy and Terms',
            body:
                'The full Privacy Policy and Terms of Service are included with '
                'this build. Ask for the copies from the Study Nova publisher if '
                'you would like to read them.',
          ),
          const SizedBox(height: 8),
          _Section(
            title: 'Support',
            body:
                'Email $supportEmail. Replace this address with your real support '
                'address before publishing the app.',
          ),
          // Only visible on a build that was made without backend configuration.
          // A published build has Supabase initialized, so a student never sees
          // this; whoever is testing an unconfigured build does, immediately.
          if (safeSupabase() == null) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade700),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Setup needed: this build has no Supabase configuration, so '
                'accounts, saved courses and synced missions are unavailable. '
                'Study Nova Labs and the study plan still work. Rebuild with '
                '--dart-define=SUPABASE_URL=... '
                '--dart-define=SUPABASE_ANON_KEY=... to enable the online '
                'features.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}
