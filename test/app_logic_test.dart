import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:three_min_meals/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('menu data', () {
    test('has at least 50 menus for every large category', () async {
      final source = await rootBundle.loadString('assets/data/menuData.json');
      final rows = (jsonDecode(source) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(rows.length, greaterThanOrEqualTo(250));
      for (final category in largeCategories) {
        expect(
          rows.where((row) => row['category_large'] == category).length,
          greaterThanOrEqualTo(50),
          reason: '$category should have at least 50 menus',
        );
      }
      expect(
        rows.every((row) => mediumCategories.contains(row['category_medium'])),
        isTrue,
      );
      expect(rows.any((row) => row['category_medium'] == '기타'), isTrue);
    });

    test('keeps curated category, tag, and price corrections', () async {
      final source = await rootBundle.loadString('assets/data/menuData.json');
      final rows = (jsonDecode(source) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      Map<String, dynamic> menu(String name) =>
          rows.singleWhere((row) => row['name'] == name);
      List<String> tags(String name) =>
          (menu(name)['tags'] as List<dynamic>).cast<String>();

      expect(menu('간짜장')['category_medium'], '면');
      expect(menu('사천짜장')['category_medium'], '면');
      expect(menu('해물짬뽕')['category_medium'], '면');
      expect(menu('알리오올리오')['category_medium'], '면');
      expect(menu('소시지플래터')['category_medium'], '육류');
      expect(menu('피쉬앤칩스')['category_medium'], '기타');
      expect(menu('해물팟타이')['category_medium'], '면');
      expect(menu('병아리콩커리')['category_medium'], '밥');
      expect(menu('비프스튜')['category_medium'], '육류');
      expect(menu('잠발라야')['category_medium'], '밥');

      expect(tags('감자탕'), containsAll(['돼지고기', '육류전체']));
      expect(tags('오삼불고기'), containsAll(['돼지고기', '육류전체', '해산물']));
      expect(tags('고추장불고기'), containsAll(['돼지고기', '육류전체', '매운맛']));
      expect(tags('등갈비찜'), containsAll(['돼지고기', '육류전체']));
      expect(tags('가츠동'), containsAll(['돼지고기', '육류전체', '밀가루']));
      expect(tags('오야코동'), containsAll(['닭고기', '육류전체']));
      expect(tags('스테이크동'), containsAll(['소고기', '육류전체']));
      expect(tags('오코노미야키'), contains('밀가루'));
      expect(tags('쌀국수'), isNot(contains('밀가루')));
      expect(tags('해물팟타이'), isNot(contains('밀가루')));
      expect(tags('브리또'), contains('밀가루'));
      expect(tags('유산슬밥'), contains('해산물'));
      expect(tags('잡탕밥'), contains('해산물'));
      expect(tags('마라샹궈'), contains('해산물'));
      expect(tags('멘보샤'), containsAll(['해산물', '갑각류']));
      expect(tags('타코야키'), contains('해산물'));
      expect(tags('차돌짬뽕'), contains('해산물'));
      expect(tags('초밥'), contains('해산물'));
      expect(tags('해산물파스타'), contains('해산물'));
      expect(tags('해산물리조또'), contains('해산물'));

      expect(menu('간짜장')['base_price'], 8500);
      expect(menu('알리오올리오')['base_price'], 11500);
      expect(menu('비프스튜')['base_price'], 14500);
    });
  });

  group('filterMenus', () {
    test('filters by selected price upper bound plus 10 percent', () {
      const menus = [
        MenuItem(
          id: 1,
          name: '저가 메뉴',
          basePrice: 8900,
          categoryLarge: '한식',
          categoryMedium: '밥',
          tags: [],
          imagePath: '',
        ),
        MenuItem(
          id: 2,
          name: '범위 메뉴',
          basePrice: 10000,
          categoryLarge: '한식',
          categoryMedium: '밥',
          tags: [],
          imagePath: '',
        ),
        MenuItem(
          id: 3,
          name: '고가 메뉴',
          basePrice: 11100,
          categoryLarge: '한식',
          categoryMedium: '밥',
          tags: [],
          imagePath: '',
        ),
      ];

      final result = filterMenus(
        menus,
        targetPrice: 10000,
        excludedTags: {},
        large: {'한식'},
        medium: {'밥'},
      );

      expect(result.map((item) => item.name), ['저가 메뉴', '범위 메뉴']);
    });

    test('supports multiple large and medium categories', () {
      const menus = [
        MenuItem(
          id: 1,
          name: '한식 밥',
          basePrice: 10000,
          categoryLarge: '한식',
          categoryMedium: '밥',
          tags: [],
          imagePath: '',
        ),
        MenuItem(
          id: 2,
          name: '중식 면',
          basePrice: 10000,
          categoryLarge: '중식',
          categoryMedium: '면',
          tags: [],
          imagePath: '',
        ),
        MenuItem(
          id: 3,
          name: '일식 육류',
          basePrice: 10000,
          categoryLarge: '일식',
          categoryMedium: '육류',
          tags: [],
          imagePath: '',
        ),
      ];

      final result = filterMenus(
        menus,
        targetPrice: 10000,
        excludedTags: {},
        large: {'한식', '중식'},
        medium: {'밥', '면'},
      );

      expect(result.map((item) => item.name), ['한식 밥', '중식 면']);
    });

    test('excludes blocked tags', () {
      const menus = [
        MenuItem(
          id: 1,
          name: '제육덮밥',
          basePrice: 10000,
          categoryLarge: '한식',
          categoryMedium: '밥',
          tags: ['돼지고기'],
          imagePath: '',
        ),
        MenuItem(
          id: 2,
          name: '김밥',
          basePrice: 10000,
          categoryLarge: '한식',
          categoryMedium: '밥',
          tags: [],
          imagePath: '',
        ),
      ];

      final result = filterMenus(
        menus,
        targetPrice: 10000,
        excludedTags: {'돼지고기'},
        large: {'한식'},
        medium: {'밥'},
      );

      expect(result.map((item) => item.name), ['김밥']);
    });

    test('excludes seafood-heavy menu names when seafood is blocked', () async {
      final source = await rootBundle.loadString('assets/data/menuData.json');
      final menus = (jsonDecode(source) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(MenuItem.fromJson)
          .toList();

      final result = filterMenus(
        menus,
        targetPrice: 30000,
        excludedTags: {'해산물'},
        large: {},
        medium: {},
      );
      final names = result.map((item) => item.name).toSet();

      expect(names, isNot(contains('유산슬밥')));
      expect(names, isNot(contains('잡탕밥')));
      expect(names, isNot(contains('마라샹궈')));
      expect(names, isNot(contains('멘보샤')));
      expect(names, isNot(contains('타코야키')));
      expect(names, isNot(contains('차돌짬뽕')));
      expect(names, isNot(contains('초밥')));
      expect(names, isNot(contains('해산물파스타')));
      expect(names, isNot(contains('해산물리조또')));
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
    test('chooses the nearest playable bracket size at or above the likes', () {
      expect(targetTournamentSize(3), 4);
      expect(targetTournamentSize(5), 6);
      expect(targetTournamentSize(7), 8);
      expect(targetTournamentSize(11), 12);
      expect(targetTournamentSize(14), 16);
      expect(targetTournamentSize(21), 24);
      expect(targetTournamentSize(40), 48);
      expect(targetTournamentSize(60), 64);
    });

    test('fills a 7-like session to the nearest playable bracket', () {
      final yes = List.generate(7, (index) => scored(index + 1));
      final no = List.generate(4, (index) => scored(index + 20));

      final tournament = Tournament.fromSwipeResults(yes, no, Random(1));

      expect(tournament.initialRound.length, 8);
      expect(tournament.byeSeeds, isEmpty);
      expect(tournament.initialRound.where((item) => item.isWildcard).length, 1);
    });

    test('fills a 14-like session to the nearest playable bracket', () {
      final yes = List.generate(14, (index) => scored(index + 1));
      final no = List.generate(5, (index) => scored(index + 20));

      final tournament = Tournament.fromSwipeResults(yes, no, Random(1));

      expect(tournament.initialRound.length, 16);
      expect(tournament.byeSeeds, isEmpty);
      expect(tournament.initialRound.where((item) => item.isWildcard).length, 2);
    });

    test('fills a 21-like session to the nearest playable bracket', () {
      final yes = List.generate(21, (index) => scored(index + 1));
      final no = List.generate(5, (index) => scored(index + 50));

      final tournament = Tournament.fromSwipeResults(yes, no, Random(1));

      expect(tournament.initialRound.length, 24);
      expect(tournament.byeSeeds, isEmpty);
      expect(tournament.initialRound.where((item) => item.isWildcard).length, 3);
    });

    test('fills a 40-like session to a 48-player bracket', () {
      final yes = List.generate(40, (index) => scored(index + 1));
      final no = List.generate(10, (index) => scored(index + 100));

      final tournament = Tournament.fromSwipeResults(yes, no, Random(1));

      expect(tournament.initialRound.length, 48);
      expect(tournament.byeSeeds, isEmpty);
      expect(tournament.initialRound.where((item) => item.isWildcard).length, 8);
    });

    test('creates bye seeds when rejected menus cannot fill the target size', () {
      final yes = List.generate(10, (index) => scored(index + 1));

      final tournament = Tournament.fromSwipeResults(yes, [], Random(1));

      expect(tournament.initialRound.length, 4);
      expect(tournament.byeSeeds.length, 6);
    });

    test('caps oversized tournaments at 64 selected menus', () {
      final yes = List.generate(90, (index) => scored(index + 1));

      final tournament = Tournament.fromSwipeResults(yes, [], Random(1));

      expect(tournament.initialRound.length + tournament.byeSeeds.length, 64);
    });
  });
}

ScoredMenu scored(int id) {
  return ScoredMenu(
    MenuItem(
      id: id,
      name: '메뉴$id',
      basePrice: 10000,
      categoryLarge: '한식',
      categoryMedium: '밥',
      tags: const [],
      imagePath: '',
    ),
    id.toDouble(),
  );
}
