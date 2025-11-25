import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kraft_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // [수정됨] MyApp -> KraftApp (ProviderScope 추가)
    await tester.pumpWidget(const ProviderScope(child: KraftApp()));

    // Smoke test logic would go here
    // 현재 앱 구조와 맞지 않는 카운터 테스트 로직은 삭제하거나 수정해야 합니다.
    // 여기서는 앱이 정상적으로 빌드되는지만 확인합니다.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}