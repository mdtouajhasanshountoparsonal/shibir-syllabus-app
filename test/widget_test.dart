import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shibir_syllabus_tracker/data/models/enums.dart';
import 'package:shibir_syllabus_tracker/shared/widgets/empty_state.dart';
import 'package:shibir_syllabus_tracker/shared/widgets/status_pill.dart';

void main() {
  testWidgets('StatusPill shows the Bangla status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusPill(status: StudyStatus.needsRevision),
        ),
      ),
    );
    expect(find.text('আবার পড়তে হবে'), findsOneWidget);
  });

  testWidgets('EmptyState renders title and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'খালি',
            message: 'এখনো কিছু নেই',
            actionLabel: 'যোগ করো',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('খালি'), findsOneWidget);
    expect(find.text('এখনো কিছু নেই'), findsOneWidget);
    await tester.tap(find.text('যোগ করো'));
    expect(tapped, isTrue);
  });
}
