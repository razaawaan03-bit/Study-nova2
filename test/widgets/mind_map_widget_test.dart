import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studynova/widgets/mind_map_widget.dart';

void main() {
  const defaultTopic = 'Photosynthesis';

  const fullMindMap = {
    'root': 'Photosynthesis',
    'branches': [
      {
        'name': 'Light Reactions',
        'children': [
          'Occurs in the thylakoid membrane',
          'Produces ATP and NADPH',
        ],
      },
      {
        'name': 'Calvin Cycle',
        'children': ['Fixes carbon dioxide', 'Occurs in the stroma'],
      },
    ],
  };

  Widget buildWidget(
    Map<String, dynamic> mindMapData, {
    String topic = defaultTopic,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MindMapWidget(mindMapData: mindMapData, topic: topic),
      ),
    );
  }

  group('MindMapWidget', () {
    testWidgets('renders the root node from mind map data', (tester) async {
      await tester.pumpWidget(buildWidget(fullMindMap));

      expect(find.text('Photosynthesis'), findsOneWidget);
    });

    testWidgets('falls back to the topic when root is missing', (tester) async {
      await tester.pumpWidget(
        buildWidget(const {'branches': []}, topic: 'Quadratic Equations'),
      );

      expect(find.text('Quadratic Equations'), findsOneWidget);
    });

    testWidgets('renders every branch and its children', (tester) async {
      await tester.pumpWidget(buildWidget(fullMindMap));

      expect(find.text('Light Reactions'), findsOneWidget);
      expect(find.text('Calvin Cycle'), findsOneWidget);
      expect(find.text('• Occurs in the thylakoid membrane'), findsOneWidget);
      expect(find.text('• Produces ATP and NADPH'), findsOneWidget);
      expect(find.text('• Fixes carbon dioxide'), findsOneWidget);
      expect(find.text('• Occurs in the stroma'), findsOneWidget);
    });

    testWidgets('shows an empty state when there are no branches', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(const {'root': 'Cell Biology'}));

      expect(find.text('Cell Biology'), findsOneWidget);
      expect(find.text('No sub-topics to display'), findsOneWidget);
    });

    testWidgets('collapses and re-expands a branch when tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(fullMindMap));

      final childFinder = find.text('• Produces ATP and NADPH');
      expect(childFinder, findsOneWidget);

      // Collapse the branch -> children are hidden.
      await tester.ensureVisible(find.text('Light Reactions'));
      await tester.tap(find.text('Light Reactions'));
      await tester.pumpAndSettle();
      expect(childFinder, findsNothing);

      // Other branches stay expanded.
      expect(find.text('• Occurs in the stroma'), findsOneWidget);

      // Expand it again -> children come back.
      await tester.tap(find.text('Light Reactions'));
      await tester.pumpAndSettle();
      expect(childFinder, findsOneWidget);
    });

    testWidgets('handles an empty mind map without errors', (tester) async {
      await tester.pumpWidget(buildWidget(const {}, topic: 'Empty Topic'));

      expect(tester.takeException(), isNull);
      expect(find.text('Empty Topic'), findsOneWidget);
      expect(find.text('No sub-topics to display'), findsOneWidget);
    });

    testWidgets('tolerates malformed AI branch data', (tester) async {
      await tester.pumpWidget(
        buildWidget(const {
          'root': 'Cell Division',
          'branches': [
            'not a branch map',
            null,
            {
              'name': 'Mitosis',
              // Nested objects and nulls instead of plain strings.
              'children': [
                {'name': 'Prophase'},
                null,
                'Metaphase',
                {'title': 'Anaphase'},
                {'text': 'Telophase'},
                {'unexpected': 'no label'},
              ],
            },
            {'children': 42},
          ],
        }),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Cell Division'), findsOneWidget);
      expect(find.text('Mitosis'), findsOneWidget);
      expect(find.text('• Prophase'), findsOneWidget);
      expect(find.text('• Metaphase'), findsOneWidget);
      expect(find.text('• Anaphase'), findsOneWidget);
      expect(find.text('• Telophase'), findsOneWidget);
      // Branch without a name falls back to 'Node'.
      expect(find.text('Node'), findsOneWidget);
    });
  });
}
