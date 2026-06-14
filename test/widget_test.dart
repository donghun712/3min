import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:three_min_meals/main.dart';

void main() {
  testWidgets('shows excluded food onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          excludedTags: const {},
          onDone: (_) {},
        ),
      ),
    );

    expect(find.text('3분세끼'), findsOneWidget);
    expect(find.text('결정하기 귀찮은 한 끼를 빠르게 좁혀드려요.'), findsOneWidget);
    expect(find.text('못먹는 음식 설정하기'), findsOneWidget);
  });
}
