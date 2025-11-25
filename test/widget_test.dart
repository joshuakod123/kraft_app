import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kraft_app/main.dart';

void main() {
  testWidgets('App builds correctly', (WidgetTester tester) async {
    // [수정] MyApp -> KraftApp
    await tester.pumpWidget(const ProviderScope(child: KraftApp()));

    // 기본 테스트: MaterialApp이 잘 생성되는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}