import 'package:flutter/material.dart';
import 'package:studynova/models/study_scan_model.dart';
import 'package:studynova/services/study_scan_service.dart';
import 'package:intl/intl.dart';
import 'study_library_detail_screen.dart';

class StudyLibraryScreen extends StatefulWidget {
  const StudyLibraryScreen({super.key});

  @override
  State<StudyLibraryScreen> createState() => _StudyLibraryScreenState();
}

class _StudyLibraryScreenState extends State<StudyLibraryScreen> {
  final StudyScanService _service = StudyScanService();
  late Future<List<StudyScanModel>> _studyScans;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshStudyScans();
  }

  void _refreshStudyScans() {
    setState(() {
      _studyScans = _service.getUserStudyScans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Study Library'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStudyScans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by topic or subject...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Study scans list
          Expanded(
            child: FutureBuilder<List<StudyScanModel>>(
              future: _studyScans,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(context, snapshot.error);
                }

                final allScans = snapshot.data ?? [];

                // Filter by search
                final filteredScans = allScans.where((scan) {
                  final query = _searchController.text.toLowerCase();
                  return scan.topic.toLowerCase().contains(query) ||
                      scan.subject.toLowerCase().contains(query);
                }).toList();

                if (filteredScans.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredScans.length,
                  itemBuilder: (context, index) {
                    final scan = filteredScans[index];
                    return _buildStudyScanCard(context, scan);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Explains the failure in plain language instead of printing the raw
  /// exception, and offers the one action that can actually help.
  Widget _buildErrorState(BuildContext context, Object? error) {
    final message = (error?.toString() ?? '').replaceFirst('Exception: ', '');

    // Being signed out is not an error state - it is a normal situation with
    // a clear next step.
    final signedOut =
        !_service.isCloudAvailable || message.toLowerCase().contains('sign in');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              signedOut ? Icons.lock_outline : Icons.cloud_off,
              size: 56,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            Text(
              signedOut
                  ? 'Sign in to see your library'
                  : 'Could not load your library',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              // The service already reports the real, friendly reason (not
              // configured / backend unreachable / signed out). A fixed
              // "check your internet connection" line here used to blame the
              // student's connection for problems that have nothing to do
              // with it.
              signedOut
                  ? 'Your saved photo explanations are stored securely in your '
                        'account.'
                  : message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (signedOut)
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
              )
            else
              ElevatedButton.icon(
                onPressed: _refreshStudyScans,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No study scans yet'
                  : 'No results found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by taking a photo of study material',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/study-from-photo'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take First Photo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyScanCard(BuildContext context, StudyScanModel scan) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final date = scan.createdAt ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => StudyLibraryDetailScreen(studyScan: scan),
                ),
              )
              .then((_) => _refreshStudyScans());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image thumbnail
              if (scan.imageUrl != null)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      scan.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade600,
                  ),
                ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic
                    Text(
                      scan.topic,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Subject and date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            scan.subject,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateFormat.format(date),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick actions
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickActionChip(
                          context,
                          icon: Icons.description,
                          label: 'Explanation',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => StudyLibraryDetailScreen(
                                      studyScan: scan,
                                      initialTab: 0,
                                    ),
                                  ),
                                )
                                .then((_) => _refreshStudyScans());
                          },
                        ),
                        _buildQuickActionChip(
                          context,
                          icon: Icons.account_tree,
                          label: 'Mind Map',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => StudyLibraryDetailScreen(
                                      studyScan: scan,
                                      initialTab: 1,
                                    ),
                                  ),
                                )
                                .then((_) => _refreshStudyScans());
                          },
                        ),
                        _buildQuickActionChip(
                          context,
                          icon: Icons.quiz,
                          label: 'Quiz',
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => StudyLibraryDetailScreen(
                                      studyScan: scan,
                                      initialTab: 2,
                                    ),
                                  ),
                                )
                                .then((_) => _refreshStudyScans());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                    onTap: () => _deleteStudyScan(context, scan),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStudyScan(
    BuildContext context,
    StudyScanModel scan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Study Scan?'),
        content: Text('Delete "${scan.topic}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && scan.id != null) {
      try {
        await _service.deleteStudyScan(scan.id!);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✓ Study scan deleted')));
        _refreshStudyScans();
      } catch (e) {
        if (!context.mounted) return;
        debugPrint('StudyLibrary: delete failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this item. Please try again.'),
          ),
        );
      }
    }
  }
}
