import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appPrimary = Color(0xffff6b35);
const appText = Color(0xff111827);
const appMutedText = Color(0xff6b7280);
const appLine = Color(0xffe5e7eb);
const appSoftSurface = Color(0xfff8fafc);
const appLike = Color(0xff22c55e);
const appDislike = Color(0xfff43f5e);

const keyFirstLaunch = 'KEY_FIRST_LAUNCH';
const keyMaxPrice = 'KEY_MAX_PRICE';
const keyExcludedTags = 'KEY_EXCLUDED_TAGS';
const keyRecentWins = 'KEY_RECENT_WINS';
const keyMealHistory = 'KEY_MEAL_HISTORY';

const largeCategories = ['한식', '중식', '양식', '일식', '기타'];
const mediumCategories = ['밥', '면', '육류', '기타'];
const dislikeTags = [
  '돼지고기',
  '소고기',
  '닭고기',
  '육류전체',
  '해산물',
  '생선',
  '갑각류',
  '매운맛',
  '유제품',
  '밀가루',
  '버섯',
  '고수',
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

  Future<void> _finishOnboarding(Set<String> excludedTags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(keyExcludedTags, excludedTags.toList());
    await prefs.setBool(keyFirstLaunch, false);
    setState(() {
      _firstLaunch = false;
      _excludedTags = excludedTags;
    });
  }

  Future<void> _setExcludedTags(Set<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(keyExcludedTags, tags.toList());
    setState(() => _excludedTags = tags);
  }

  Future<void> _setDefaultPrice(int price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyMaxPrice, price);
    setState(() => _maxPrice = price);
  }

  Future<void> _saveMeal(String menuName) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final record = MealRecord(
      menuName: menuName,
      createdAt: now,
      periodLabel: mealPeriodLabel(now),
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
          seedColor: appPrimary,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        dividerColor: appLine,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: appText,
          surfaceTintColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xffffeee6),
          surfaceTintColor: Colors.white,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? appPrimary : appMutedText,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? appPrimary : appMutedText,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: appPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: appText,
            side: const BorderSide(color: appLine),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: appSoftSurface,
          selectedColor: const Color(0xffffeee6),
          checkmarkColor: appPrimary,
          side: const BorderSide(color: appLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: appText,
              displayColor: appText,
            ),
      ),
      home: FutureBuilder<void>(
        future: _bootFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingScreen();
          }
          if (_firstLaunch) {
            return OnboardingScreen(
              excludedTags: _excludedTags,
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
            onDefaultPriceChanged: _setDefaultPrice,
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
    required this.onDefaultPriceChanged,
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
  final ValueChanged<int> onDefaultPriceChanged;
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
        onDefaultPriceChanged: widget.onDefaultPriceChanged,
        onMealConfirmed: widget.onMealConfirmed,
      ),
      RandomTab(
        menus: widget.menus,
        defaultPrice: widget.maxPrice,
        excludedTags: widget.excludedTags,
        onDefaultPriceChanged: widget.onDefaultPriceChanged,
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
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.emoji_events), label: '추천'),
          NavigationDestination(icon: Icon(Icons.shuffle), label: '랜덤'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '기록'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

enum RecommendStage {
  idle,
  price,
  large,
  medium,
  swiping,
  result,
  tournament,
}

class RecommendTab extends StatefulWidget {
  const RecommendTab({
    required this.menus,
    required this.defaultPrice,
    required this.excludedTags,
    required this.recentWins,
    required this.onDefaultPriceChanged,
    required this.onMealConfirmed,
    super.key,
  });

  final List<MenuItem> menus;
  final int defaultPrice;
  final Set<String> excludedTags;
  final List<String> recentWins;
  final ValueChanged<int> onDefaultPriceChanged;
  final ValueChanged<String> onMealConfirmed;

  @override
  State<RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<RecommendTab> {
  final Random _random = Random();
  final List<ScoredMenu> _yes = [];
  final List<ScoredMenu> _no = [];
  RecommendStage _stage = RecommendStage.idle;
  List<MenuItem> _candidates = [];
  Tournament? _tournament;
  int _price = 12000;
  Set<String> _large = {};
  Set<String> _medium = {};
  int _index = 0;
  int _remaining = 10;
  DateTime _shownAt = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _price = widget.defaultPrice;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetFlow() {
    _timer?.cancel();
    setState(() {
      _stage = RecommendStage.idle;
      _candidates = [];
      _tournament = null;
      _yes.clear();
      _no.clear();
      _large = {};
      _medium = {};
      _index = 0;
      _remaining = 10;
    });
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _stage = RecommendStage.price;
      _price = widget.defaultPrice;
      _candidates = [];
      _tournament = null;
      _yes.clear();
      _no.clear();
      _large = {};
      _medium = {};
      _index = 0;
    });
  }

  void _choosePrice() {
    widget.onDefaultPriceChanged(_price);
    setState(() => _stage = RecommendStage.large);
  }

  void _toggleLarge(String category) {
    setState(() {
      final next = {..._large};
      next.contains(category) ? next.remove(category) : next.add(category);
      _large = next;
    });
  }

  void _toggleMedium(String category) {
    setState(() {
      final next = {..._medium};
      next.contains(category) ? next.remove(category) : next.add(category);
      _medium = next;
    });
  }

  void _confirmLarge() {
    if (_large.isEmpty) {
      _showSnack('카테고리를 하나 이상 골라주세요.');
      return;
    }
    setState(() => _stage = RecommendStage.medium);
  }

  void _confirmMedium() {
    if (_medium.isEmpty) {
      _showSnack('밥, 면, 육류, 기타 중 하나 이상 골라주세요.');
      return;
    }
    final candidates = filterMenus(
      widget.menus,
      targetPrice: _price,
      excludedTags: widget.excludedTags,
      large: _large,
      medium: _medium,
    )..shuffle(_random);
    setState(() {
      _candidates = candidates.take(64).toList();
      _index = 0;
      _yes.clear();
      _no.clear();
      _stage = _candidates.isEmpty ? RecommendStage.result : RecommendStage.swiping;
    });
    if (_candidates.isNotEmpty) _startCardTimer();
  }

  void _startCardTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = 10;
      _shownAt = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _stage != RecommendStage.swiping) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        _decide(liked: false, timedOut: true);
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _decide({required bool liked, bool timedOut = false}) {
    if (_stage != RecommendStage.swiping || _index >= _candidates.length) return;
    _timer?.cancel();
    var seconds = DateTime.now().difference(_shownAt).inMilliseconds / 1000;
    if (timedOut || seconds >= 10) {
      seconds = 10;
      liked = false;
    }
    final scored = ScoredMenu(_candidates[_index], seconds);
    setState(() {
      liked ? _yes.add(scored) : _no.add(scored);
      _index += 1;
      if (_index >= _candidates.length) {
        _stage = RecommendStage.result;
      }
    });
    if (_stage == RecommendStage.swiping) {
      _startCardTimer();
    }
  }

  void _buildTournament() {
    if (_yes.isEmpty) {
      _showSnack('좋아요를 받은 메뉴가 없어요. 조건을 다시 골라볼까요?');
      return;
    }
    if (_yes.length == 1) {
      _showWinner(_yes.first);
      return;
    }
    setState(() {
      _tournament = Tournament.fromSwipeResults(_yes, _no, _random);
      _stage = RecommendStage.tournament;
    });
  }

  void _showWinner(ScoredMenu winner) {
    showDialog<void>(
      context: context,
      builder: (context) => WinnerDialog(
        winner: winner,
        onConfirm: () {
          Navigator.of(context).pop();
          widget.onMealConfirmed(winner.menu.name);
          _resetFlow();
        },
      ),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (_stage) {
        RecommendStage.idle => _IdleStep(onStart: _start),
        RecommendStage.price => _PriceStep(
            price: _price,
            onChanged: (value) => setState(() => _price = value),
            onNext: _choosePrice,
            onBack: _resetFlow,
            nextLabel: '카테고리 고르기',
          ),
        RecommendStage.large => _MultiChoiceStep(
            title: '어떤 종류가 끌려요?',
            subtitle: '한식과 중식처럼 여러 개를 함께 고를 수 있어요.',
            options: largeCategories,
            selected: _large,
            onToggle: _toggleLarge,
            onNext: _confirmLarge,
            onBack: () => setState(() => _stage = RecommendStage.price),
          ),
        RecommendStage.medium => _MultiChoiceStep(
            title: '오늘의 형태는?',
            subtitle: '밥, 면, 육류, 기타도 여러 개를 함께 고를 수 있어요.',
            options: mediumCategories,
            selected: _medium,
            onToggle: _toggleMedium,
            onNext: _confirmMedium,
            onBack: () => setState(() => _stage = RecommendStage.large),
          ),
        RecommendStage.swiping => _SwipeStep(
            candidates: _candidates,
            index: _index,
            remaining: _remaining,
            targetPrice: _price,
            recentWins: widget.recentWins,
            onLike: () => _decide(liked: true),
            onDislike: () => _decide(liked: false),
          ),
        RecommendStage.result => _ResultStep(
            candidatesCount: _candidates.length,
            yesCount: _yes.length,
            noCount: _no.length,
            onTournament: _buildTournament,
            onRestart: _start,
          ),
        RecommendStage.tournament => TournamentView(
            tournament: _tournament!,
            onFinished: _showWinner,
          ),
      },
    );
  }
}

enum RandomStage { price, result }

class RandomTab extends StatefulWidget {
  const RandomTab({
    required this.menus,
    required this.defaultPrice,
    required this.excludedTags,
    required this.onDefaultPriceChanged,
    required this.onMealConfirmed,
    super.key,
  });

  final List<MenuItem> menus;
  final int defaultPrice;
  final Set<String> excludedTags;
  final ValueChanged<int> onDefaultPriceChanged;
  final ValueChanged<String> onMealConfirmed;

  @override
  State<RandomTab> createState() => _RandomTabState();
}

class _RandomTabState extends State<RandomTab> {
  final Random _random = Random();
  RandomStage _stage = RandomStage.price;
  int _price = 12000;
  List<MenuItem> _candidates = [];
  ScoredMenu? _winner;

  @override
  void initState() {
    super.initState();
    _price = widget.defaultPrice;
  }

  void _reset() {
    setState(() {
      _stage = RandomStage.price;
      _price = widget.defaultPrice;
      _candidates = [];
      _winner = null;
    });
  }

  void _pick() {
    widget.onDefaultPriceChanged(_price);
    final candidates = filterMenus(
      widget.menus,
      targetPrice: _price,
      excludedTags: widget.excludedTags,
      large: const <String>{},
      medium: const <String>{},
    );
    setState(() {
      _candidates = candidates;
      _winner = candidates.isEmpty
          ? null
          : ScoredMenu(candidates[_random.nextInt(candidates.length)], 0);
      _stage = RandomStage.result;
    });
  }

  void _reroll() {
    if (_candidates.isEmpty) return;
    setState(() {
      _winner = ScoredMenu(
        _candidates[_random.nextInt(_candidates.length)],
        0,
      );
    });
  }

  void _confirm() {
    final selected = _winner;
    if (selected == null) return;
    widget.onMealConfirmed(selected.menu.name);
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (_stage) {
        RandomStage.price => _PriceStep(
            price: _price,
            title: '순수 랜덤',
            subtitle: '가격대만 고르면 못먹는 음식 태그를 제외하고 바로 하나 뽑아요.',
            onChanged: (value) => setState(() => _price = value),
            onNext: _pick,
            onBack: _reset,
            nextLabel: '랜덤 추천 받기',
          ),
        RandomStage.result => _RandomResultStep(
            winner: _winner,
            candidateCount: _candidates.length,
            targetPrice: _price,
            onReroll: _reroll,
            onRestart: _reset,
            onConfirm: _winner == null ? null : _confirm,
          ),
      },
    );
  }
}

class _IdleStep extends StatelessWidget {
  const _IdleStep({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          const Text('가격대와 카테고리를 고른 뒤, 10초 안에 메뉴를 넘겨보세요.'),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('추천 시작'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PriceStep extends StatelessWidget {
  const _PriceStep({
    required this.price,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
    this.title = '원하는 가격대',
    this.subtitle = '선택한 가격대와 그보다 저렴한 메뉴를 보여드려요.',
    this.nextLabel = '다음',
  });

  final int price;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(
            title: title,
            subtitle: subtitle,
            onBack: onBack,
          ),
          const Spacer(),
          Text(
            '평균 ${money(price)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          Slider(
            min: 5000,
            max: 30000,
            divisions: 25,
            value: price.toDouble(),
            label: money(price),
            onChanged: (value) => onChanged(value.round()),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            child: Text(nextLabel),
          ),
        ],
      ),
    );
  }
}

class _MultiChoiceStep extends StatelessWidget {
  const _MultiChoiceStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onNext,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(title: title, subtitle: subtitle, onBack: onBack),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selected.contains(option);
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onToggle(option),
                  child: Container(
                    height: 86,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? appPrimary
                            : appLine,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? const Color(0xfffff3ed)
                          : appSoftSurface,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? appPrimary : appMutedText,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: selected.isEmpty ? null : onNext,
            child: const Text('다음'),
          ),
        ],
      ),
    );
  }
}

class _SwipeStep extends StatefulWidget {
  const _SwipeStep({
    required this.candidates,
    required this.index,
    required this.remaining,
    required this.targetPrice,
    required this.recentWins,
    required this.onLike,
    required this.onDislike,
  });

  final List<MenuItem> candidates;
  final int index;
  final int remaining;
  final int targetPrice;
  final List<String> recentWins;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  @override
  State<_SwipeStep> createState() => _SwipeStepState();
}

class _SwipeStepState extends State<_SwipeStep> {
  double _dragDx = 0;
  bool _isExiting = false;
  int _exitDirection = 0;
  bool _showHint = true;

  @override
  void didUpdateWidget(covariant _SwipeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _dragDx = 0;
      _isExiting = false;
      _exitDirection = 0;
      _showHint = widget.index == 0;
    }
  }

  void _finishSwipe(bool liked) {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
      _exitDirection = liked ? 1 : -1;
      _showHint = false;
      _dragDx = _exitDirection * (MediaQuery.sizeOf(context).width + 160);
    });
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      liked ? widget.onLike() : widget.onDislike();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.candidates[widget.index];
    final width = MediaQuery.sizeOf(context).width;
    final normalizedDrag = (_dragDx / width).clamp(-1.0, 1.0).toDouble();
    final rotation = normalizedDrag * 0.11;
    final overlayOpacity = normalizedDrag.abs().clamp(0.0, 0.85).toDouble();
    final isLikeDirection = normalizedDrag > 0;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: widget.remaining / 10,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Text('${widget.remaining}초'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '선택 가격 ${money(widget.targetPrice)} · ${money(priceUpperBound(widget.targetPrice))} 이하',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                if (_isExiting) return;
                setState(() {
                  _dragDx = 0;
                  _showHint = false;
                });
              },
              onHorizontalDragUpdate: (details) {
                if (_isExiting) return;
                setState(() => _dragDx += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                if (_isExiting) return;
                final velocity = details.primaryVelocity ?? 0;
                if (_dragDx > 48 || velocity > 180) {
                  _finishSwipe(true);
                } else if (_dragDx < -48 || velocity < -180) {
                  _finishSwipe(false);
                } else {
                  setState(() => _dragDx = 0);
                }
              },
              child: AnimatedContainer(
                duration: _isExiting
                    ? const Duration(milliseconds: 250)
                    : const Duration(milliseconds: 180),
                curve: _isExiting ? Curves.easeInOutCubic : Curves.easeOutCubic,
                transformAlignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setTranslationRaw(_dragDx, 0, 0)
                  ..rotateZ(rotation),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MenuCard(
                      menu: menu,
                      badge: recentWinBadge(menu.name, widget.recentWins),
                    ),
                    Positioned(
                      top: 22,
                      left: isLikeDirection ? null : 22,
                      right: isLikeDirection ? 22 : null,
                      child: Opacity(
                        opacity: overlayOpacity,
                        child: _SwipeStamp(
                          text: isLikeDirection ? '좋아요' : '싫어요',
                          color: isLikeDirection
                              ? appLike
                              : appDislike,
                          icon: isLikeDirection
                              ? Icons.favorite
                              : Icons.close,
                        ),
                      ),
                    ),
                    if (_showHint)
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: _SwipeHint(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.index + 1} / ${widget.candidates.length}',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.arrow_back, color: appMutedText, size: 18),
                SizedBox(width: 6),
                Text('싫어요', style: TextStyle(color: appText)),
              ],
            ),
            Row(
              children: [
                Text('좋아요', style: TextStyle(color: appText)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, color: appMutedText, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({
    required this.candidatesCount,
    required this.yesCount,
    required this.noCount,
    required this.onTournament,
    required this.onRestart,
  });

  final int candidatesCount;
  final int yesCount;
  final int noCount;
  final VoidCallback onTournament;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final noCandidate = candidatesCount == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              noCandidate ? '후보가 없어요' : '선택 완료',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              noCandidate
                  ? '가격대나 못먹는 음식 태그를 조금 풀어보세요.'
                  : '좋아요 $yesCount개 · 탈락 $noCount개',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!noCandidate)
              FilledButton.icon(
                onPressed: onTournament,
                icon: const Icon(Icons.emoji_events),
                label: const Text('토너먼트 시작'),
              ),
            TextButton(
              onPressed: onRestart,
              child: const Text('다시 고르기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RandomResultStep extends StatelessWidget {
  const _RandomResultStep({
    required this.winner,
    required this.candidateCount,
    required this.targetPrice,
    required this.onReroll,
    required this.onRestart,
    required this.onConfirm,
  });

  final ScoredMenu? winner;
  final int candidateCount;
  final int targetPrice;
  final VoidCallback onReroll;
  final VoidCallback onRestart;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final selected = winner;
    if (selected == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '랜덤 후보가 없어요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '${money(priceUpperBound(targetPrice))} 이하에서 못먹는 음식 필터를 적용했더니 남는 메뉴가 없어요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRestart,
                child: const Text('가격 다시 고르기'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeader(
            title: '랜덤 추천',
            subtitle:
                '${money(priceUpperBound(targetPrice))} 이하 · 후보 $candidateCount개 중 하나',
            onBack: onRestart,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.97, end: 1).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                );
              },
              child: MenuCard(
                key: ValueKey(selected.menu.id),
                menu: selected.menu,
                badge: '순수 랜덤',
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check),
            label: const Text('식사 완료 기록하기'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReroll,
            icon: const Icon(Icons.shuffle),
            label: const Text('다시 랜덤'),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로',
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
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
  final List<_TournamentLoser> _currentRoundLosers = [];
  int _matchIndex = 0;
  DateTime _matchStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _round = widget.tournament.initialRound;
    _byeSeeds = widget.tournament.byeSeeds;
    _matchStartedAt = DateTime.now();
  }

  void _pick(ScoredMenu menu) {
    final left = _round[_matchIndex];
    final right = _round[_matchIndex + 1];
    final loser = menu.menu.id == left.menu.id ? right : left;
    final dwellSeconds =
        DateTime.now().difference(_matchStartedAt).inMilliseconds / 1000;
    _currentRoundLosers.add(_TournamentLoser(loser, dwellSeconds));
    _winners.add(menu);
    if (_matchIndex + 2 >= _round.length) {
      final nextRound = [..._winners, ..._byeSeeds];
      final revivalCount = switch (nextRound.length) {
        3 => 1,
        6 => 2,
        _ => 0,
      };
      if (revivalCount > 0) {
        final revivals = [..._currentRoundLosers]
          ..sort((a, b) => b.dwellSeconds.compareTo(a.dwellSeconds));
        nextRound.addAll(
          revivals.take(revivalCount).map((item) => item.menu.asWildcard()),
        );
      }
      nextRound.shuffle(Random());
      if (nextRound.length == 1) {
        widget.onFinished(nextRound.first);
        return;
      }
      setState(() {
        _round = nextRound;
        _byeSeeds = [];
        _winners.clear();
        _currentRoundLosers.clear();
        _matchIndex = 0;
        _matchStartedAt = DateTime.now();
      });
      return;
    }
    setState(() {
      _matchIndex += 2;
      _matchStartedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final left = _round[_matchIndex];
    final right = _round[_matchIndex + 1];
    final byeText = _byeSeeds.isEmpty ? '' : ' · 부전승 ${_byeSeeds.length}개';
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_round.length + _byeSeeds.length}강 · ${(_matchIndex ~/ 2) + 1}경기$byeText',
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
      return const EmptyState(text: '아직 기록이 없어요.\n우승 메뉴를 기록하면 여기에 쌓입니다.');
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
          '못먹는 음식',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        const Text('처음 선택한 태그는 언제든 여기서 바꿀 수 있어요.'),
        const SizedBox(height: 16),
        TagSelector(
          selectedTags: excludedTags,
          onChanged: onExcludedTagsChanged,
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.excludedTags,
    required this.onDone,
    super.key,
  });

  final Set<String> excludedTags;
  final ValueChanged<Set<String>> onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late Set<String> _selectedTags;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _selectedTags = {...widget.excludedTags};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _showIntro
                ? Column(
                    key: const ValueKey('intro'),
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
                      const Text('결정하기 귀찮은 한 끼를 빠르게 좁혀드려요.'),
                      const SizedBox(height: 28),
                      const _IntroPoint(
                        icon: Icons.tune,
                        title: '가격과 카테고리 선택',
                        body: '선택한 가격대 이하의 메뉴에서 한식/중식, 밥/면/기타 등을 고릅니다.',
                      ),
                      const _IntroPoint(
                        icon: Icons.swipe,
                        title: '10초 메뉴 카드',
                        body: '오른쪽은 좋아요, 왼쪽은 싫어요예요. 첫 카드에서 한 번 더 알려드릴게요.',
                      ),
                      const _IntroPoint(
                        icon: Icons.emoji_events,
                        title: '토너먼트 결정',
                        body: '좋아요 메뉴끼리 붙이고, 애매한 숫자는 와일드카드와 부전승으로 맞춥니다.',
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => setState(() => _showIntro = false),
                        child: const Text('못먹는 음식 설정하기'),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('tags'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '못먹는 음식',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text('선택한 태그가 들어간 메뉴는 추천에서 제외할게요. 나중에 설정에서 바꿀 수 있어요.'),
                      const SizedBox(height: 22),
                      Expanded(
                        child: SingleChildScrollView(
                          child: TagSelector(
                            selectedTags: _selectedTags,
                            onChanged: (tags) => setState(() => _selectedTags = tags),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _showIntro = true),
                              child: const Text('이전'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => widget.onDone(_selectedTags),
                              child: const Text('추천 시작하기'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _IntroPoint extends StatelessWidget {
  const _IntroPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TagSelector extends StatelessWidget {
  const TagSelector({
    required this.selectedTags,
    required this.onChanged,
    super.key,
  });

  final Set<String> selectedTags;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in dislikeTags)
          FilterChip(
            label: Text(tag),
            selected: selectedTags.contains(tag),
            onSelected: (selected) {
              final next = {...selectedTags};
              selected ? next.add(tag) : next.remove(tag);
              onChanged(next);
            },
          ),
      ],
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: appLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Chip(
              label: Text(badge!),
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              side: const BorderSide(color: appLine),
            ),
          const Spacer(),
          Text(
            menu.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: appText,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 24 : 34,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MenuPill(text: menu.categoryLarge),
              _MenuPill(text: menu.categoryMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '평균 ${money(menu.basePrice)}',
            style: const TextStyle(
              color: appPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuPill extends StatelessWidget {
  const _MenuPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: appMutedText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
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
          Text('${winner.menu.categoryLarge} · ${winner.menu.categoryMedium} · ${money(winner.menu.basePrice)}'),
          if (winner.isWildcard) ...[
            const SizedBox(height: 8),
            const Text('오래 고민하다 탈락했지만 다시 살아난 와일드카드였어요.'),
          ],
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
      decoration: const BoxDecoration(
        color: appSoftSurface,
        border: Border(top: BorderSide(color: appLine)),
      ),
      child: const Text(
        '',
        style: TextStyle(color: appMutedText, fontSize: 12),
      ),
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

class _TournamentLoser {
  const _TournamentLoser(this.menu, this.dwellSeconds);

  final ScoredMenu menu;
  final double dwellSeconds;
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
    final sortedNo = [...no]
      ..sort((a, b) => b.dwellSeconds.compareTo(a.dwellSeconds));
    final entrants = sortedYes.take(64).toList();
    final target = targetTournamentSize(entrants.length);
    final wildcardsNeeded = max(0, target - entrants.length);
    entrants.addAll(sortedNo.take(wildcardsNeeded).map((item) => item.asWildcard()));

    if (isPlayableTournamentSize(entrants.length)) {
      entrants.shuffle(random);
      return Tournament(initialRound: entrants);
    }

    final power = largestPowerOfTwoAtMost(entrants.length);
    final eliminate = entrants.length - power;
    final sortedEntrants = [...entrants]
      ..sort((a, b) => a.dwellSeconds.compareTo(b.dwellSeconds));
    final playIn = sortedEntrants.take(eliminate * 2).toList()..shuffle(random);
    final byes = sortedEntrants.skip(eliminate * 2).toList()..shuffle(random);
    return Tournament(initialRound: playIn, byeSeeds: byes);
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
  required int targetPrice,
  required Set<String> excludedTags,
  required Set<String> large,
  required Set<String> medium,
}) {
  final upperBound = priceUpperBound(targetPrice);
  return menus.where((menu) {
    if (menu.basePrice > upperBound) return false;
    if (large.isNotEmpty && !large.contains(menu.categoryLarge)) return false;
    if (medium.isNotEmpty && !medium.contains(menu.categoryMedium)) return false;
    if (menu.tags.any(excludedTags.contains)) return false;
    return true;
  }).toList();
}

int priceUpperBound(int targetPrice) => (targetPrice * 1.1).round();

int targetTournamentSize(int count) {
  const playableSizes = [4, 6, 8, 12, 16, 24, 32, 48, 64];
  for (final size in playableSizes) {
    if (count <= size) return size;
  }
  return 64;
}

bool isPowerOfTwo(int value) {
  return value > 1 && (value & (value - 1)) == 0;
}

bool isPlayableTournamentSize(int value) {
  const playableSizes = {4, 6, 8, 12, 16, 24, 32, 48, 64};
  return playableSizes.contains(value);
}

int largestPowerOfTwoAtMost(int value) {
  var power = 1;
  while (power * 2 <= value) {
    power *= 2;
  }
  return power;
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
  return '$buffer원';
}

String? recentWinBadge(String name, List<String> wins) {
  final count = wins.where((item) => item == name).length;
  if (count == 0) return null;
  return '최근 10판 중 $count회 우승작';
}

List<Color> cardColors(int id) {
  const palettes = [
    [Color(0xfffff3ed), Color(0xfffffbf7)],
    [Color(0xffecfffb), Color(0xfff8fffd)],
    [Color(0xfff1f7ff), Color(0xfffbfdff)],
    [Color(0xfffff8dc), Color(0xfffffdf3)],
    [Color(0xfff7f2ff), Color(0xfffdfbff)],
    [Color(0xfff8fafc), Color(0xffffffff)],
  ];
  return palettes[id % palettes.length];
}
