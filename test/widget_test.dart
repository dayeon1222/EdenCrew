import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/main.dart';

void main() {
  testWidgets('시작 화면이 다크 테마로 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const EdencrewAssignmentApp(),
    );

    await tester.pumpAndSettle();

    expect(
      Theme.of(
        tester.element(
          find.byType(Scaffold).first,
        ),
      ).brightness,
      Brightness.dark,
    );
  });
}
