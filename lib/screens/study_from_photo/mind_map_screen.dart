import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/mind_map_widget.dart';

class MindMapScreen extends StatefulWidget {
  final String topic;
  final Map<String, dynamic> mindMapData;

  const MindMapScreen({
    super.key,
    required this.topic,
    required this.mindMapData,
  });

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Map'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMindMap,
            tooltip: 'Share mind map',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isSaving ? null : _saveMindMap,
            tooltip: 'Save mind map',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MindMapWidget(
              mindMapData: widget.mindMapData,
              topic: widget.topic,
            ),
          ),
          // Bottom info bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.blue.shade600),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to explore',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.blue.shade600),
                    const SizedBox(height: 4),
                    Text(
                      'Scroll to zoom',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMindMap() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // For now, show a snack bar
      // In a complete implementation, you would capture the mind map as an image
      // and save it to device storage

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mind map is automatically saved with your study!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this mind map. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareMindMap() async {
    try {
      // Generate text representation of the mind map
      final textContent = _generateMindMapText();

      await Share.share(textContent, subject: '${widget.topic} - Mind Map');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share this mind map. Please try again.'),
        ),
      );
    }
  }

  String _generateMindMapText() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln(widget.topic);
    buffer.writeln('━' * widget.topic.length);
    buffer.writeln();

    final branches = widget.mindMapData['branches'] as List? ?? [];
    for (var branch in branches) {
      if (branch is Map<String, dynamic>) {
        final name = branch['name'] as String? ?? 'Node';
        final children = branch['children'] as List? ?? [];

        buffer.writeln('├─ $name');
        for (var i = 0; i < children.length; i++) {
          final child = children[i] as String? ?? '';
          if (i == children.length - 1) {
            buffer.writeln('│  └─ $child');
          } else {
            buffer.writeln('│  ├─ $child');
          }
        }
      }
    }

    return buffer.toString();
  }
}
