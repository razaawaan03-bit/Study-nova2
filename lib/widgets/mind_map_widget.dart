import 'package:flutter/material.dart';

class MindMapWidget extends StatefulWidget {
  final Map<String, dynamic> mindMapData;
  final String topic;

  const MindMapWidget({
    super.key,
    required this.mindMapData,
    required this.topic,
  });

  @override
  State<MindMapWidget> createState() => _MindMapWidgetState();
}

class _MindMapWidgetState extends State<MindMapWidget> {
  late Map<String, bool> _expandedNodes;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeExpandedState();
  }

  void _initializeExpandedState() {
    _expandedNodes = {};
    final branches = widget.mindMapData['branches'] as List?;
    if (branches != null) {
      for (var i = 0; i < branches.length; i++) {
        _expandedNodes['branch_$i'] = true;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final root = widget.mindMapData['root'] as String? ?? widget.topic;
    final branches = widget.mindMapData['branches'] as List? ?? [];

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Root node
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  root,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Branches
            if (branches.isEmpty)
              Center(
                child: Text(
                  'No sub-topics to display',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              )
            else
              ...List.generate(branches.length, (index) {
                final rawBranch = branches[index];
                if (rawBranch is! Map) return const SizedBox.shrink();

                return _buildBranchNode(
                  context,
                  branch: Map<String, dynamic>.from(rawBranch),
                  nodeId: 'branch_$index',
                  depth: 0,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchNode(
    BuildContext context, {
    required Map<String, dynamic> branch,
    required String nodeId,
    required int depth,
  }) {
    final name = branch['name']?.toString() ?? 'Node';
    final children = _normalizeChildren(branch['children']);
    final isExpanded = _expandedNodes[nodeId] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branch node
        Padding(
          padding: EdgeInsets.only(left: depth * 24.0),
          child: InkWell(
            onTap: () => setState(() => _expandedNodes[nodeId] = !isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getColorForDepth(depth),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getColorForDepth(depth).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (children.isNotEmpty)
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  if (children.isNotEmpty) const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Connector line and children
        if (isExpanded && children.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: depth * 24.0 + 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(children.length, (childIndex) {
                final childNodeId = '${nodeId}_child_$childIndex';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horizontal connector
                    Container(
                      width: 20,
                      height: 2,
                      color: Colors.grey.shade400,
                    ),
                    // Child item
                    _buildChildNode(
                      context,
                      childName: children[childIndex],
                      nodeId: childNodeId,
                      depth: depth + 1,
                    ),
                  ],
                );
              }),
            ),
          ),

        if (children.isNotEmpty) const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChildNode(
    BuildContext context, {
    required String childName,
    required String nodeId,
    required int depth,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: 12, left: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _getColorForDepth(depth).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getColorForDepth(depth).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '• $childName',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Converts raw child entries into displayable labels.
  ///
  /// The mind map data comes straight from the AI response, so children may be
  /// plain strings, nested objects, or nulls. Anything unreadable is dropped
  /// instead of throwing during build.
  List<String> _normalizeChildren(dynamic rawChildren) {
    if (rawChildren is! List) return const [];

    return rawChildren
        .map((child) {
          if (child is Map) {
            final label = child['name'] ?? child['title'] ?? child['text'];
            return label?.toString() ?? '';
          }
          return child?.toString() ?? '';
        })
        .where((label) => label.trim().isNotEmpty)
        .toList();
  }

  Color _getColorForDepth(int depth) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
    ];
    return colors[depth % colors.length];
  }
}
