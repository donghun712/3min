import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:three_min_meals/main.dart';

void main() {
  group('filterMenus', () {
    test('filters by price, category, and excluded tags', () {
      const menus = [
        MenuItem(
          id: 1,
          name: '김치찌개',
          basePrice: 9000,
          categoryLarge: '한식',
          categoryMedium: '국물',
          tags: ['돼지고기', '매운맛'],
          imagePath: '',
        ),
        MenuItem(
          id: 2,
          name: '쌀국수',
          basePrice: 10500,
          categoryLarge: '기타',
          categoryMedium: '면',
          tags: ['고수'],
          imagePath: '',
        ),
        MenuItem(
          id: 3,
          name: '김밥',
          basePrice: 4500,
          categoryLarge: '한식',
          categoryMedium: '밥',
          tags: [],
          imagePath: '',
        ),
      ];

      final result = filterMenus(
        menus,
        maxPrice: 10000,
        excludedTags: {'돼지고기'},
        large: {'한식'},
        medium: {},
      );

      expect(result.map((item) => item.name), ['김밥']);
    });
  });

  group('mealPeriodLabel', () {
    test('maps hours to meal periods', () {
      expect(mealPeriodLabel(DateTime(2026, 1, 1, 5)), '아침');
      expect(mealPeriodLabel(DateTime(2026, 1, 1, 11)), '점심');
      expect(mealPeriodLabel(DateTime(2026, 1, 1, 16)), '저녁');
      expect(mealPeriodLabel(DateTime(2026, 1, 1, 22)), '야식');
      expect(mealPeriodLabel(DateTime(2026, 1, 1, 4)), '야식');
    });
  });

  group('Tournament', () {
    test('adds wildcards for 6 selected menus', () {
      final yes = List.generate(6, (index) => scored(index + 1));
      final no = List.generate(2, (index) => scored(index + 20));

      final tournament = Tournament.fromSwipeResults(yes, no, Random(1));

      expect(tournament.initialRound.length, 8);
      expect(tournament.byeSeeds, isEmpty);
      expect(tournament.initialRound.where((item) => item.isWildcard).length, 2);
    });

    test('creates bye seeds for 10 selected menus', () {
      final yes = List.generate(10, (index) => scored(index + 1));

      final tournament = Tournament.fromSwipeResults(yes, [], Random(1));

      expect(tournament.initialRound.length, 4);
      expect(tournament.byeSeeds.length, 6);
    });

    test('caps oversized tournaments at 16 selected menus', () {
      final yes = List.generate(24, (index) => scored(index + 1));

      final tournament = Tournament.fromSwipeResults(yes, [], Random(1));

      expect(tournament.initialRound.length + tournament.byeSeeds.length, 16);
    });
  });
}

ScoredMenu scored(int id) {
  return ScoredMenu(
    MenuItem(
      id: id,
      name: '메뉴$id',
      basePrice: 8000,
      categoryLarge: '한식',
      categoryMedium: '밥',
      tags: const [],
      imagePath: '',
    ),
    id.toDouble(),
  );
}
