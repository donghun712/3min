import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const keyFirstLaunch = 'KEY_FIRST_LAUNCH';
const keyMaxPrice = 'KEY_MAX_PRICE';
const keyExcludedTags = 'KEY_EXCLUDED_TAGS';
const keyRecentWins = 'KEY_RECENT_WINS';
const keyMealHistory = 'KEY_MEAL_HISTORY';

const largeCategories = ['한식', '중식', '일식', '양식/패스트푸드', '기타'];
const mediumCategories = ['밥', '면', '국물', '고기·요리', '기타/패스트푸드'];
const dislikeTags = [
  '돼지고기',
  '소고기',
  '닭고기',
  '육류전체/채식',
  '해산물',
  '갑각류',
  '생선류',
  '오이',
  '고수',
  '버섯',
  '매운맛',
  '느끼함',
  '마늘/파',
  '유제품',
  '밀가루',
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ThreeMinMealsApp());
}

class ThreeMinMealsApp extends StatefulWidget {
  const ThreeMinMealsApp({super.key});

  @override
  State<ThreeMinMealsApp> createState() => _ThreeMinMealsAppState();
}

class _ThreeMinMealsAppState extends State<ThreeMinMealsApp> {
  late Future<void> _bootFuture;
  List<MenuItem> _menus = [];
  bool _firstLaunch = true;
  int _maxPrice = 12000;
  Set<String> _excludedTags = {};
  List<String> _recentWins = [];
  List<MealRecord> _mealHistory = [];

  @override
  void initState() {
    super.initState();
    _bootFuture = _boot();
  }

  Future<void> _boot() async {
    final jsonText = await rootBundle.loadString('assets/data/menuData.json');
    final decoded = jsonDecode(jsonText) as List<dynamic>;
    final prefs = await SharedPreferences.getInstance();
    _menus = decoded
        .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
        .toList();
    _firstLaunch = prefs.getBool(keyFirstLaunch) ?? true;
    _maxPrice = prefs.getInt(keyMaxPrice) ?? 12000;
    _excludedTags = (prefs.getStringList(keyExcludedTags) ?? []).toSet();
    _recentWins = prefs.getStringList(keyRecentWins) ?? [];
    _mealHistory = (prefs.getStringList(keyMealHistory) ?? [])
        .map(MealRecord.fromJsonString)
        .whereType<MealRecord>()
        .toList();
  }

  Future<void> _finishOnboarding(int price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyMaxPrice, price);
    await prefs.setBool(keyFirstLaunch, false);
    setState(() {
      _firstLaunch = false;
      _maxPrice = price;
    });
  }

  Future<void> _setExcludedTags(Set<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(keyExcludedTags, tags.toList());
    setState(() => _excludedTags = tags);
  }

  Future<void> _saveMeal(String menuName) async {
    final prefs = await SharedPreferences.getInstance();
    final record = MealRecord(
      menuName: menuName,
      createdAt: DateTime.now(),
      periodLabel: mealPeriodLabel(DateTime.now()),
    );
    final history = [record, ..._mealHistory].take(10).toList();
    final wins = [menuName, ..._recentWins].take(10).toList();
    await prefs.setStringList(
      keyMealHistory,
      history.map((item) => item.toJsonString()).toList(),
    );
    await prefs.setStringList(keyRecentWins, wins);
    setState(() {
      _mealHistory = history;
      _recentWins = wins;
    });
  }

  Future<void> _updateMeal(int index, String name) async {
    if (index < 0 || index >= _mealHistory.length) return;
    final prefs = await SharedPreferences.getInstance();
    final history = [..._mealHistory];
    history[index] = history[index].copyWith(menuName: name);
    await prefs.setStringList(
      keyMealHistory,
      history.map((item) => item.toJsonString()).toList(),
    );
    setState(() => _mealHistory = history);
  }

  Future<void> _resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _firstLaunch = true;
      _maxPrice = 12000;
      _excludedTags = {};
      _recentWins = [];
      _mealHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '3분세끼',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xfff05a28),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<void>(
        future: _bootFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingScreen();
          }
          if (_firstLaunch) {
            return OnboardingScreen(
              initialPrice: _maxPrice,
              onDone: _finishOnboarding,
            );
          }
          return MainShell(
            menus: _menus,
            maxPrice: _maxPrice,
            excludedTags: _excludedTags,
            recentWins: _recentWins,
            mealHistory: _mealHistory,
            onMealConfirmed: _saveMeal,
            onExcludedTagsChanged: _setExcludedTags,
            onMealChanged: _updateMeal,
            onReset: _resetData,
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    required this.menus,
    required this.maxPrice,
    required this.excludedTags,
    required this.recentWins,
    required this.mealHistory,
    required this.onMealConfirmed,
    required this.onExcludedTagsChanged,
    required this.onMealChanged,
    required this.onReset,
    super.key,
  });

  final List<MenuItem> menus;
  final int maxPrice;
  final Set<String> excludedTags;
  final List<String> recentWins;
  final List<MealRecord> mealHistory;
  final ValueChanged<String> onMealConfirmed;
  final ValueChanged<Set<String>> onExcludedTagsChanged;
  final Future<void> Function(int index, String name) onMealChanged;
  final VoidCallback onReset;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      RecommendTab(
        menus: widget.menus,
        defaultPrice: widget.maxPrice,
        excludedTags: widget.excludedTags,
        recentWins: widget.recentWins,
        onMealConfirmed: widget.onMealConfirmed,
      ),
      RandomTab(
        menus: widget.menus,
        defaultPrice: widget.maxPrice,
        excludedTags: widget.excludedTags,
        onMealConfirmed: widget.onMealConfirmed,
      ),
      HistoryTab(
        records: widget.mealHistory,
        onMealChanged: widget.onMealChanged,
      ),
      SettingsTab(
        excludedTags: widget.excludedTags,
        onExcludedTagsChanged: widget.onExcludedTagsChanged,
        onReset: widget.onReset,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[_tab]),
            const AdPlaceholder(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.emoji_events), label: '추천'),
          NavigationDestination(icon: Icon(Icons.flash_on), label: '랜덤'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '기록'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

class RecommendTab extends StatefulWidget {
  const RecommendTab({
    required this.menus,
    required this.defaultPrice,
    required this.excludedTags,
    required this.recentWins,
    required this.onMealConfirmed,
    super.key,
  });

  final List<MenuItem> menus;
  final int defaultPrice;
  final Set<String> excludedTags;
  final List<String> recentWins;
  final ValueChanged<String> onMealConfirmed;

  @override
  State<RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<RecommendTab> {
  final List<ScoredMenu> _yes = [];
  final List<ScoredMenu> _no = [];
  final Random _random = Random();
  Set<String> _large = {};
  Set<String> _medium = {};
  int _price = 12000;
  int _index = 0;
  DateTime _shownAt = DateTime.now();
  Tournament? _tournament;

  @override
  void initState() {
    super.initState();
    _price = widget.defaultPrice;
    _shownAt = DateTime.now();
  }

  List<MenuItem> get _candidates => filterMenus(
        widget.menus,
        maxPrice: _price,
        excludedTags: widget.excludedTags,
        large: _large,
        medium: _medium,
      );

  void _changePrice(int price) {
    setState(() {
      _price = price;
      _yes.clear();
      _no.clear();
      _index = 0;
      _tournament = null;
      _shownAt = DateTime.now();
    });
  }

  void _changeLarge(Set<String> items) {
    setState(() {
      _large = items;
      _yes.clear();
      _no.clear();
      _index = 0;
      _tournament = null;
      _shownAt = DateTime.now();
    });
  }

  void _changeMedium(Set<String> items) {
    setState(() {
      _medium = items;
      _yes.clear();
      _no.clear();
      _index = 0;
      _tournament = null;
      _shownAt = DateTime.now();
    });
  }

  void _startSwipe() {
    setState(() {
      _yes.clear();
      _no.clear();
      _index = 0;
      _tournament = null;
      _shownAt = DateTime.now();
    });
  }

  void _swipe(bool liked) {
    final candidates = _candidates;
    if (_index >= candidates.length) return;
    var seconds = DateTime.now().difference(_shownAt).inMilliseconds / 1000;
    if (seconds >= 20) seconds = 0;
    final scored = ScoredMenu(candidates[_index], seconds);
    setState(() {
      liked ? _yes.add(scored) : _no.add(scored);
      _index += 1;
      _shownAt = DateTime.now();
    });
  }

  void _buildTournament() {
    if (_yes.length < 2) {
      _showSnack('오른쪽으로 고른 메뉴가 2개 이상 필요해요.');
      return;
    }
    setState(() {
      _tournament = Tournament.fromSwipeResults(_yes, _no, _random);
    });
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    final body = _tournament == null
        ? _buildSwipeBody(candidates)
        : TournamentView(
            tournament: _tournament!,
            onFinished: (winner) {
              showDialog<void>(
                context: context,
                builder: (context) => WinnerDialog(
                  winner: winner,
                  onConfirm: () {
                    Navigator.of(context).pop();
                    widget.onMealConfirmed(winner.menu.name);
                    setState(() => _tournament = null);
                  },
                ),
              );
            },
          );

    return Column(
      children: [
        FilterPanel(
          title: '오늘 뭐 먹지?',
          price: _price,
          selectedLarge: _large,
          selectedMedium: _medium,
          onPriceChanged: _changePrice,
          onLargeChanged: _changeLarge,
          onMediumChanged: _changeMedium,
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildSwipeBody(List<MenuItem> candidates) {
    if (candidates.isEmpty) {
      return const EmptyState(text: '조건에 맞는 메뉴가 없어요.\n예산이나 필터를 조금 풀어볼까요?');
    }
    if (_index >= candidates.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '선택 완료',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
                Text('좋아요 ${_yes.length}개 · 패스 ${_no.length}개'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _buildTournament,
                icon: const Icon(Icons.sports_mma),
                label: const Text('토너먼트 시작'),
              ),
              TextButton(
                onPressed: _startSwipe,
                child: const Text('다시 고르기'),
              ),
            ],
          ),
        ),
      );
    }

    final menu = candidates[_index];
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 100) _swipe(true);
                if (velocity < -100) _swipe(false);
              },
              child: MenuCard(
                menu: menu,
                badge: recentWinBadge(menu.name, widget.recentWins),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _swipe(false),
                  icon: const Icon(Icons.close),
                  label: const Text('패스'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _swipe(true),
                  icon: const Icon(Icons.favorite),
                  label: const Text('좋아요'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_index + 1} / ${candidates.length}'),
        ],
      ),
    );
  }
}

class RandomTab extends StatefulWidget {
  const RandomTab({
    required this.menus,
    required this.defaultPrice,
    required this.excludedTags,
    required this.onMealConfirmed,
    super.key,
  });

  final List<MenuItem> menus;
  final int defaultPrice;
  final Set<String> excludedTags;
  final ValueChanged<String> onMealConfirmed;

  @override
  State<RandomTab> createState() => _RandomTabState();
}

class _RandomTabState extends State<RandomTab> {
  final Random _random = Random();
  Set<String> _large = {};
  Set<String> _medium = {};
  int _price = 12000;
  MenuItem? _result;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _price = widget.defaultPrice;
  }

  Future<void> _roll() async {
    final candidates = filterMenus(
      widget.menus,
      maxPrice: _price,
      excludedTags: widget.excludedTags,
      large: _large,
      medium: _medium,
    );
    if (candidates.isEmpty) return;
    setState(() => _rolling = true);
    for (var i = 0; i < 14; i += 1) {
      await Future<void>.delayed(const Duration(milliseconds: 95));
      if (!mounted) return;
      setState(() => _result = candidates[_random.nextInt(candidates.length)]);
    }
    setState(() => _rolling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterPanel(
          title: '에라 모르겠다',
          price: _price,
          selectedLarge: _large,
          selectedMedium: _medium,
          onPriceChanged: (price) => setState(() => _price = price),
          onLargeChanged: (items) => setState(() => _large = items),
          onMediumChanged: (items) => setState(() => _medium = items),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _result == null
                        ? const EmptyState(text: '버튼 하나로 오늘 메뉴를 정해요.')
                        : MenuCard(
                            key: ValueKey(_result!.id),
                            menu: _result!,
                            badge: _rolling ? '르르륵...' : null,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _rolling ? null : _roll,
                  icon: const Icon(Icons.casino),
                  label: Text(_result == null ? '랜덤 추천' : '다시 돌리기'),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _rolling
                        ? null
                        : () => widget.onMealConfirmed(_result!.name),
                    icon: const Icon(Icons.check),
                    label: const Text('확정'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({
    required this.records,
    required this.onMealChanged,
    super.key,
  });

  final List<MealRecord> records;
  final Future<void> Function(int index, String name) onMealChanged;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyState(text: '아직 기록이 없어요.\n먹은 메뉴를 확정하면 여기에 쌓입니다.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = records[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(record.menuName),
          subtitle: Text('${record.periodLabel} · ${formatDate(record.createdAt)}'),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final next = await showDialog<String>(
              context: context,
              builder: (context) => EditMealDialog(initialName: record.menuName),
            );
            if (next != null && next.trim().isNotEmpty) {
              await onMealChanged(index, next.trim());
            }
          },
        );
      },
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    required this.excludedTags,
    required this.onExcludedTagsChanged,
    required this.onReset,
    super.key,
  });

  final Set<String> excludedTags;
  final ValueChanged<Set<String>> onExcludedTagsChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          '기피 태그',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const Text('지금은 UI와 저장 흐름을 먼저 만들었습니다. 메뉴별 태그가 채워지면 필터에 바로 반영됩니다.'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in dislikeTags)
              FilterChip(
                label: Text(tag),
                selected: excludedTags.contains(tag),
                onSelected: (selected) {
                  final next = {...excludedTags};
                  selected ? next.add(tag) : next.remove(tag);
                  onExcludedTagsChanged(next);
                },
              ),
          ],
        ),
        const SizedBox(height: 30),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('데이터 초기화'),
                content: const Text('온보딩, 설정, 추천 기록을 모두 지울까요?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onReset();
                    },
                    child: const Text('초기화'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('앱 데이터 초기화'),
        ),
      ],
    );
  }
}

class FilterPanel extends StatelessWidget {
  const FilterPanel({
    required this.title,
    required this.price,
    required this.selectedLarge,
    required this.selectedMedium,
    required this.onPriceChanged,
    required this.onLargeChanged,
    required this.onMediumChanged,
    super.key,
  });

  final String title;
  final int price;
  final Set<String> selectedLarge;
  final Set<String> selectedMedium;
  final ValueChanged<int> onPriceChanged;
  final ValueChanged<Set<String>> onLargeChanged;
  final ValueChanged<Set<String>> onMediumChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text('${money(price)} 이하'),
              ],
            ),
            Slider(
              min: 5000,
              max: 30000,
              divisions: 25,
              value: price.toDouble(),
              label: money(price),
              onChanged: (value) => onPriceChanged(value.round()),
            ),
            _ChipRow(
              items: largeCategories,
              selected: selectedLarge,
              onChanged: onLargeChanged,
            ),
            const SizedBox(height: 6),
            _ChipRow(
              items: mediumCategories,
              selected: selectedMedium,
              onChanged: onMediumChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<String> items;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(item),
                selected: selected.contains(item),
                onSelected: (isSelected) {
                  final next = {...selected};
                  isSelected ? next.add(item) : next.remove(item);
                  onChanged(next);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class TournamentView extends StatefulWidget {
  const TournamentView({
    required this.tournament,
    required this.onFinished,
    super.key,
  });

  final Tournament tournament;
  final ValueChanged<ScoredMenu> onFinished;

  @override
  State<TournamentView> createState() => _TournamentViewState();
}

class _TournamentViewState extends State<TournamentView> {
  late List<ScoredMenu> _round;
  late List<ScoredMenu> _byeSeeds;
  final List<ScoredMenu> _winners = [];
  int _matchIndex = 0;

  @override
  void initState() {
    super.initState();
    _round = widget.tournament.initialRound;
    _byeSeeds = widget.tournament.byeSeeds;
  }

  void _pick(ScoredMenu menu) {
    _winners.add(menu);
    if (_matchIndex + 2 >= _round.length) {
      final nextRound = [..._winners, ..._byeSeeds];
      if (_winners.length == 1) {
        if (_byeSeeds.isEmpty) {
          widget.onFinished(_winners.first);
        } else {
          setState(() {
            _round = nextRound;
            _byeSeeds = [];
            _winners.clear();
            _matchIndex = 0;
          });
        }
      } else {
        setState(() {
          _round = nextRound;
          _byeSeeds = [];
          _winners.clear();
          _matchIndex = 0;
        });
      }
      return;
    }
    setState(() => _matchIndex += 2);
  }

  @override
  Widget build(BuildContext context) {
    final left = _round[_matchIndex];
    final right = _round[_matchIndex + 1];
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_round.length}강 · ${(_matchIndex ~/ 2) + 1}경기',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _TournamentChoice(menu: left, onTap: _pick)),
                const SizedBox(width: 10),
                Expanded(child: _TournamentChoice(menu: right, onTap: _pick)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentChoice extends StatelessWidget {
  const _TournamentChoice({required this.menu, required this.onTap});

  final ScoredMenu menu;
  final ValueChanged<ScoredMenu> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onTap(menu),
      child: MenuCard(
        menu: menu.menu,
        compact: true,
        badge: menu.isWildcard ? '와일드카드' : null,
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  const MenuCard({
    required this.menu,
    this.badge,
    this.compact = false,
    super.key,
  });

  final MenuItem menu;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = cardColors(menu.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Chip(
              label: Text(badge!),
              backgroundColor: Colors.white.withOpacity(0.88),
            ),
          const Spacer(),
          Text(
            menu.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 24 : 34,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${menu.categoryLarge} · ${menu.categoryMedium}',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            money(menu.basePrice),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.initialPrice,
    required this.onDone,
    super.key,
  });

  final int initialPrice;
  final ValueChanged<int> onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _price;

  @override
  void initState() {
    super.initState();
    _price = widget.initialPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                '3분세끼',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              const Text('오늘의 결정 피로를 조금 줄여볼게요.'),
              const SizedBox(height: 44),
              Text(
                '기본 예산 ${money(_price)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Slider(
                min: 5000,
                max: 30000,
                divisions: 25,
                value: _price.toDouble(),
                label: money(_price),
                onChanged: (value) => setState(() => _price = value.round()),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => widget.onDone(_price),
                child: const Text('3분세끼 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WinnerDialog extends StatelessWidget {
  const WinnerDialog({
    required this.winner,
    required this.onConfirm,
    super.key,
  });

  final ScoredMenu winner;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('오늘의 한 끼'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            winner.menu.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text('${winner.menu.categoryLarge} · ${money(winner.menu.basePrice)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        FilledButton(
          onPressed: onConfirm,
          child: const Text('식사 완료 기록하기'),
        ),
      ],
    );
  }
}

class EditMealDialog extends StatefulWidget {
  const EditMealDialog({required this.initialName, super.key});

  final String initialName;

  @override
  State<EditMealDialog> createState() => _EditMealDialogState();
}

class _EditMealDialogState extends State<EditMealDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('먹은 메뉴 수정'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '메뉴명'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: const Text('AdMob 배너 영역'),
    );
  }
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.categoryLarge,
    required this.categoryMedium,
    required this.tags,
    required this.imagePath,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      basePrice: json['base_price'] as int,
      categoryLarge: json['category_large'] as String,
      categoryMedium: json['category_medium'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      imagePath: json['image_path'] as String,
    );
  }

  final int id;
  final String name;
  final int basePrice;
  final String categoryLarge;
  final String categoryMedium;
  final List<String> tags;
  final String imagePath;
}

class ScoredMenu {
  const ScoredMenu(this.menu, this.dwellSeconds, {this.isWildcard = false});

  final MenuItem menu;
  final double dwellSeconds;
  final bool isWildcard;

  ScoredMenu asWildcard() {
    return ScoredMenu(menu, dwellSeconds, isWildcard: true);
  }
}

class Tournament {
  const Tournament({
    required this.initialRound,
    this.byeSeeds = const [],
  });

  factory Tournament.fromSwipeResults(
    List<ScoredMenu> yes,
    List<ScoredMenu> no,
    Random random,
  ) {
    final sortedYes = [...yes]
      ..sort((a, b) => b.dwellSeconds.compareTo(a.dwellSeconds));
    final tournamentYes = sortedYes.take(16).toList();
    final sortedNo = [...no]
      ..sort((a, b) => b.dwellSeconds.compareTo(a.dwellSeconds));
    final n = tournamentYes.length;
    final target = (n <= 8) ? 8 : 16;

    if ((n == 6 || n == 7 || n == 14 || n == 15) && sortedNo.isNotEmpty) {
      final needed = min(target - n, sortedNo.length);
      final merged = [
        ...tournamentYes,
        ...sortedNo.take(needed).map((item) => item.asWildcard()),
      ]..shuffle(random);
      return Tournament(initialRound: _ensureEven(merged));
    }

    final power = _largestPowerOfTwoAtMost(n);
    if (power == n) {
      final seeded = [...tournamentYes]..shuffle(random);
      return Tournament(initialRound: _ensureEven(seeded));
    }

    final eliminate = n - power;
    final low = tournamentYes.reversed.take(eliminate * 2).toList()
      ..shuffle(random);
    final byes = tournamentYes.take(max(0, n - eliminate * 2)).toList();
    return Tournament(initialRound: _ensureEven(low), byeSeeds: byes);
  }

  final List<ScoredMenu> initialRound;
  final List<ScoredMenu> byeSeeds;
}

class MealRecord {
  const MealRecord({
    required this.menuName,
    required this.createdAt,
    required this.periodLabel,
  });

  static MealRecord? fromJsonString(String source) {
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      return MealRecord(
        menuName: json['menuName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        periodLabel: json['periodLabel'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  final String menuName;
  final DateTime createdAt;
  final String periodLabel;

  MealRecord copyWith({String? menuName}) {
    return MealRecord(
      menuName: menuName ?? this.menuName,
      createdAt: createdAt,
      periodLabel: periodLabel,
    );
  }

  String toJsonString() {
    return jsonEncode({
      'menuName': menuName,
      'createdAt': createdAt.toIso8601String(),
      'periodLabel': periodLabel,
    });
  }
}

List<MenuItem> filterMenus(
  List<MenuItem> menus, {
  required int maxPrice,
  required Set<String> excludedTags,
  required Set<String> large,
  required Set<String> medium,
}) {
  return menus.where((menu) {
    if (menu.basePrice > maxPrice) return false;
    if (large.isNotEmpty && !large.contains(menu.categoryLarge)) return false;
    if (medium.isNotEmpty && !medium.contains(menu.categoryMedium)) return false;
    if (menu.tags.any(excludedTags.contains)) return false;
    return true;
  }).toList();
}

String mealPeriodLabel(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 11) return '아침';
  if (hour >= 11 && hour < 16) return '점심';
  if (hour >= 16 && hour < 22) return '저녁';
  return '야식';
}

String formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

String money(int value) {
  final source = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < source.length; i += 1) {
    final remaining = source.length - i;
    buffer.write(source[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${buffer}원';
}

String? recentWinBadge(String name, List<String> wins) {
  final count = wins.where((item) => item == name).length;
  if (count == 0) return null;
  return '최근 10판 중 $count회 우승작';
}

List<Color> cardColors(int id) {
  const palettes = [
    [Color(0xfff05a28), Color(0xfff7b733)],
    [Color(0xff11998e), Color(0xff38ef7d)],
    [Color(0xff396afc), Color(0xff2948ff)],
    [Color(0xff834d9b), Color(0xffd04ed6)],
    [Color(0xffcb2d3e), Color(0xffef473a)],
    [Color(0xff232526), Color(0xff414345)],
  ];
  return palettes[id % palettes.length];
}

int _largestPowerOfTwoAtMost(int value) {
  var power = 1;
  while (power * 2 <= value) {
    power *= 2;
  }
  return power;
}

List<ScoredMenu> _ensureEven(List<ScoredMenu> items) {
  if (items.length.isEven) return items;
  return items.take(items.length - 1).toList();
}
