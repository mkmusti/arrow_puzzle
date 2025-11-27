import 'dart:math';
import 'dart:async';
// import 'dart:ui' as ui; // Kullanılmıyorsa kaldırılabilir
import 'package:arrow_puzzle/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// --- ÖNEMLİ: Flutter'ın ürettiği çeviri dosyasını import ediyoruz --

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const SnakePuzzleApp());
}

// --- 1. SABİTLER VE TEMA ---
class AppColors {
  static const bg = Color(0xFF1A1A2E);
  static const gridDot = Color(0xFF323B58);
  static const accent = Color(0xFFE94560);
  static const collision = Color(0xFFFF0000);
  static const success = Color(0xFF00E676);
  static const cardBg = Color(0xFF16213E);
  static const textSecondary = Color(0xFF8E9AAF);
}

class SnakePuzzleApp extends StatelessWidget {
  const SnakePuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.gameTitle,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      ),
      // --- ADIM 4: Yerelleştirmeyi Aktif Etme ---
      // Flutter'ın ürettiği hazır listeleri kullanıyoruz:
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // -------------------------------------------
      home: const GameScreen(),
    );
  }
}

// --- 2. SES YÖNETİCİSİ ---
class SoundManager {
  static Future<void> play(String fileName) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/$fileName'));
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      // debugPrint("Ses hatası: $e");
    }
  }
}

// --- 3. REKLAM WIDGET'I (RealAdBanner) ---
class RealAdBanner extends StatefulWidget {
  const RealAdBanner({super.key});

  @override
  State<RealAdBanner> createState() => _RealAdBannerState();
}

class _RealAdBannerState extends State<RealAdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // SİZİN GERÇEK AD UNIT ID'NİZ
  final String _adUnitId = 'ca-app-pub-6890807918605748/3307495661';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Çeviri nesnesine erişim
    final l10n = AppLocalizations.of(context)!;

    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        color: Colors.white,
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Yüklenmezse yer tutucu (Çevrildi)
    return Container(
      width: double.infinity,
      height: 50,
      color: Colors.black,
      alignment: Alignment.center,
      child: Text(
        l10n.bannerAdPlaceholder, // "REKLAM YÜKLENİYOR..."
        style: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
    );
  }
}

// --- 4. VERİ MODELLERİ (Değişiklik Yok) ---
enum Direction { up, down, left, right }

class Point {
  final int x, y;
  const Point(this.x, this.y);
  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator -(Point other) => Point(x - other.x, y - other.y);
  Point operator *(int factor) => Point(x * factor, y * factor);
  @override
  bool operator ==(Object other) => other is Point && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

class Snake {
  final String id;
  final List<Point> body;
  final Direction exitDirection;
  Color originalColor;
  Color displayColor;
  bool isExited = false;
  double currentOffset = 0.0;

  Snake({
    required this.id,
    required this.body,
    required this.exitDirection,
    required this.originalColor,
  }) : displayColor = originalColor;

  Point get head => body.last;
  Point get tail => body.first;

  Snake clone() {
    return Snake(
        id: id,
        body: List.from(body),
        exitDirection: exitDirection,
        originalColor: originalColor
    );
  }
}

// --- 5. OYUN MANTIĞI (CONTROLLER) ---
class GameController extends ChangeNotifier {
  int rows = 12;
  int cols = 10;
  List<Snake> snakes = [];
  bool isGenerating = false;
  final Map<String, AnimationController> _animControllers = {};

  int level = 1;
  int lives = 3;
  // String difficultyLabel = "Basit"; // <-- KALDIRILDI: Artık UI'da çevrilecek
  bool isGameOver = false;
  bool isLevelSuccess = false;

  Timer? _timer;
  int totalSeconds = 0;
  int levelSeconds = 0;
  bool showHourWarning = false;

  double get boardWidth => cols * 38.0;
  double get boardHeight => rows * 38.0;
  int get remainingSnakes => snakes.where((s) => !s.isExited).length;

  GameController() {
    startNewLevel();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameOver && !isGenerating && !isLevelSuccess) {
        totalSeconds++;
        levelSeconds++;

        if (totalSeconds == 3600) showHourWarning = true;
        else if (totalSeconds == 3605) showHourWarning = false;

        notifyListeners();
      }
    });
  }

  String getFormattedTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void nextLevel() {
    level++;
    startNewLevel();
  }

  void restartGame() {
    level = 1;
    totalSeconds = 0;
    startNewLevel();
  }

  void _configureLevel() {
    int maxLen;
    int minSnakeCount;
    int maxSnakeCount;
    int difficultyIndex = (level - 1) % 6;

    // difficultyLabel atamaları KALDIRILDI. Sadece mantık kaldı.
    switch (difficultyIndex) {
      case 0: // BASİT
        cols = 10; rows = 12; maxLen = 7; minSnakeCount = 40; maxSnakeCount = 55;
        break;
      case 1: // KOLAY
        cols = 12; rows = 15; maxLen = 9; minSnakeCount = 65; maxSnakeCount = 85;
        break;
      case 2: // NORMAL
        cols = 14; rows = 18; maxLen = 11; minSnakeCount = 90; maxSnakeCount = 120;
        break;
      case 3: // ZOR
        cols = 16; rows = 22; maxLen = 14; minSnakeCount = 130; maxSnakeCount = 160;
        break;
      case 4: // ÇOK ZOR
        cols = 18; rows = 26; maxLen = 17; minSnakeCount = 170; maxSnakeCount = 210;
        break;
      case 5: // KABUS
        cols = 20; rows = 30; maxLen = 20; minSnakeCount = 220; maxSnakeCount = 280;
        break;
      default:
        cols = 14; rows = 18; maxLen = 11; minSnakeCount = 90; maxSnakeCount = 120;
    }
    _generateLevelSafe(maxLen, minSnakeCount, maxSnakeCount);
  }

  Future<void> startNewLevel() async {
    isGenerating = true;
    isGameOver = false;
    isLevelSuccess = false;
    levelSeconds = 0;
    if (level == 1 || lives <= 0) lives = 3;

    snakes.clear();
    _disposeControllers();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));
    _configureLevel();
  }

  // ... (Geri kalan _generateLevelSafe, _fillRemainingGaps, _simulateSolution,
  // _canExitSimulated, _getDirVector, isValid, handleTap, _calculateFreeSteps,
  // _animateCollision, _animateExit, _checkLevelComplete metodları aynen kalacak) ...
  // KODUN UZAMAMASI İÇİN BU KISIMLARI TEKRAR YAZMIYORUM, ORİJİNAL KODUNUZDAKİ GİBİ KALMALI.
  // EĞER KOPYALA-YAPIŞTIR YAPARKEN BU KISIMLAR EKSİK KALIRSA LÜTFEN SÖYLEYİN TAMAMINI ATAYIM.
  // ANCAK EN SAĞLIKLISI, GameController'ın _configureLevel'a kadar olan üst kısmını değiştirip,
  // alt tarafını (mantık fonksiyonlarını) korumaktır.

  // --- GameController'ın Alt Kısım Başlangıcı (Korumaya Alınan Kısım) ---
  void _generateLevelSafe(int maxLen, int minSnakes, int maxSnakes) {
    final Random rng = Random();
    final Set<Point> occupied = {};
    snakes.clear();

    int snakeIdCounter = 0;
    int totalCells = rows * cols;
    int targetSnakeCount = minSnakes + rng.nextInt(maxSnakes - minSnakes + 1);
    int failsInARow = 0;
    int globalAttempts = 0;

    while (snakes.length < targetSnakeCount && failsInARow < 100 && globalAttempts < 4000) {
      globalAttempts++;
      if (occupied.length > totalCells * 0.98) break;

      Point startHeadPos = const Point(0, 0);
      Direction entryDir = Direction.up;
      bool strategyFound = false;
      bool tryBlock = snakes.isNotEmpty && rng.nextDouble() > 0.5;

      if (tryBlock) {
        List<Snake> shuffled = List.from(snakes)..shuffle(rng);
        for (var targetSnake in shuffled) {
          Point dirVec = _getDirVector(targetSnake.exitDirection);
          Point checkPos = targetSnake.head + dirVec;
          for(int dist=0; dist<2; dist++) {
            if (isValid(checkPos) && !occupied.contains(checkPos)) {
              startHeadPos = checkPos;
              if (targetSnake.exitDirection == Direction.up || targetSnake.exitDirection == Direction.down) {
                entryDir = rng.nextBool() ? Direction.left : Direction.right;
              } else {
                entryDir = rng.nextBool() ? Direction.up : Direction.down;
              }
              strategyFound = true;
              break;
            }
            checkPos = checkPos + dirVec;
          }
          if (strategyFound) break;
        }
      }

      if (!strategyFound) {
        entryDir = Direction.values[rng.nextInt(4)];
        startHeadPos = Point(rng.nextInt(cols), rng.nextInt(rows));
      }

      if (!isValid(startHeadPos) || occupied.contains(startHeadPos)) {
        failsInARow++;
        continue;
      }

      int currentMaxLen = maxLen;
      if (occupied.length / totalCells > 0.5) currentMaxLen = max(3, maxLen ~/ 2);
      if (occupied.length / totalCells > 0.8) currentMaxLen = 3;

      int desiredLen = rng.nextInt(currentMaxLen - 2) + 3;
      List<Point> path = [startHeadPos];
      Point currentTail = startHeadPos;
      Point currentGrowth = _getDirVector(entryDir) * -1;

      bool stuck = false;
      for(int i=0; i<desiredLen-1; i++) {
        List<Point> candidates = [];
        Map<Point, Point> growthMap = {};
        Point p1 = currentTail + currentGrowth;
        candidates.add(p1); growthMap[p1] = currentGrowth;

        if (i > 0) {
          Point axis = (currentGrowth.x == 0) ? const Point(1,0) : const Point(0,1);
          Point t1 = currentTail + axis;
          Point t2 = currentTail + (axis * -1);
          candidates.add(t1); growthMap[t1] = axis;
          candidates.add(t2); growthMap[t2] = axis * -1;
        }

        List<Point> valid = [];
        for(var c in candidates) {
          if (isValid(c) && !occupied.contains(c) && !path.contains(c)) valid.add(c);
        }

        if (valid.isEmpty) { stuck = true; break; }
        Point chosen = valid[rng.nextInt(valid.length)];
        path.add(chosen);
        currentTail = chosen;
        currentGrowth = growthMap[chosen]!;
      }

      if (!stuck && path.length >= 2) {
        Color c = Color((rng.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
        if (c.computeLuminance() < 0.4) c = HSLColor.fromColor(c).withLightness(0.6).toColor();

        Snake candidate = Snake(
            id: (snakeIdCounter).toString(),
            body: path.reversed.toList(),
            exitDirection: entryDir,
            originalColor: c
        );

        snakes.add(candidate);
        if (_simulateSolution(snakes)) {
          occupied.addAll(path);
          snakeIdCounter++;
          failsInARow = 0;
        } else {
          snakes.removeLast();
          failsInARow++;
        }
      } else {
        failsInARow++;
      }
    }

    if (snakes.length < targetSnakeCount) {
      _fillRemainingGaps(occupied, rng, snakeIdCounter, targetSnakeCount);
    }

    isGenerating = false;
    notifyListeners();
  }

  void _fillRemainingGaps(Set<Point> occupied, Random rng, int startId, int targetCount) {
    int idCounter = startId;
    List<Point> emptyCells = [];
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        Point p = Point(x, y);
        if (!occupied.contains(p)) emptyCells.add(p);
      }
    }
    emptyCells.shuffle(rng);

    for (Point p in emptyCells) {
      if (snakes.length >= targetCount) break;
      if (occupied.contains(p)) continue;

      List<Direction> dirs = Direction.values.toList()..shuffle(rng);
      for (Direction d in dirs) {
        Point growthDir = _getDirVector(d) * -1;
        List<Point> currentPath = [p];
        Point currentTail = p;
        Point currentGrowth = growthDir;

        for(int len=0; len<3; len++) {
          List<Point> candidates = [];
          Map<Point, Point> gMap = {};
          Point s = currentTail + currentGrowth;
          candidates.add(s); gMap[s] = currentGrowth;
          if (len > 0) {
            Point axis = (currentGrowth.x == 0) ? const Point(1,0) : const Point(0,1);
            Point t1 = currentTail + axis;
            Point t2 = currentTail + (axis * -1);
            candidates.add(t1); gMap[t1] = axis;
            candidates.add(t2); gMap[t2] = axis * -1;
          }
          List<Point> valid = [];
          for(var c in candidates) {
            if(isValid(c) && !occupied.contains(c) && !currentPath.contains(c)) valid.add(c);
          }
          if (valid.isNotEmpty) {
            Point chosen = valid[rng.nextInt(valid.length)];
            currentPath.add(chosen);
            currentTail = chosen;
            currentGrowth = gMap[chosen]!;
          } else { break; }
        }

        if (currentPath.length >= 2) {
          Color c = Color((rng.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
          if (c.computeLuminance() < 0.4) c = HSLColor.fromColor(c).withLightness(0.6).toColor();

          Snake fillerSnake = Snake(
              id: (idCounter).toString(),
              body: currentPath.reversed.toList(),
              exitDirection: d,
              originalColor: c
          );

          snakes.add(fillerSnake);
          if (_simulateSolution(snakes)) {
            occupied.addAll(currentPath);
            idCounter++;
            break;
          } else {
            snakes.removeLast();
          }
        }
      }
    }
  }

  bool _simulateSolution(List<Snake> currentSnakes) {
    if (currentSnakes.isEmpty) return true;
    List<Snake> simSnakes = currentSnakes.map((s) => s.clone()).toList();
    Set<Point> simOccupied = {};
    for (var s in simSnakes) simOccupied.addAll(s.body);
    bool progressMade = true;
    while (progressMade && simSnakes.isNotEmpty) {
      progressMade = false;
      List<Snake> toRemove = [];
      for (var snake in simSnakes) {
        if (_canExitSimulated(snake, simOccupied)) {
          toRemove.add(snake);
          progressMade = true;
          simOccupied.removeAll(snake.body);
        }
      }
      for (var s in toRemove) simSnakes.remove(s);
    }
    return simSnakes.isEmpty;
  }

  bool _canExitSimulated(Snake snake, Set<Point> occupiedMap) {
    Point dirVec = _getDirVector(snake.exitDirection);
    Point current = snake.head;
    int limit = max(rows, cols) + snake.body.length;
    while (limit-- > 0) {
      current = current + dirVec;
      if (!isValid(current)) return true;
      if (occupiedMap.contains(current)) return false;
    }
    return true;
  }

  Point _getDirVector(Direction d) {
    switch(d) {
      case Direction.up: return const Point(0, -1);
      case Direction.down: return const Point(0, 1);
      case Direction.left: return const Point(-1, 0);
      case Direction.right: return const Point(1, 0);
    }
  }

  bool isValid(Point p) => p.x >= 0 && p.x < cols && p.y >= 0 && p.y < rows;

  void handleTap(Point tapPoint, TickerProvider vsync) {
    if (isGenerating || lives <= 0 || isLevelSuccess) return;

    SoundManager.play('click.mp3');

    Snake? tappedSnake;
    for (var s in snakes) {
      if (!s.isExited && s.body.contains(tapPoint)) {
        tappedSnake = s;
        break;
      }
    }

    if (tappedSnake == null) return;
    if (_animControllers.containsKey(tappedSnake.id) && _animControllers[tappedSnake.id]!.isAnimating) return;

    int freeSteps = _calculateFreeSteps(tappedSnake);

    if (freeSteps >= 500) {
      _animateExit(tappedSnake, vsync);
    } else {
      lives--;
      SoundManager.play('bump.mp3');
      notifyListeners();
      _animateCollision(tappedSnake, freeSteps, vsync);

      if (lives <= 0) {
        isGameOver = true;
        SoundManager.play('gameover.mp3');
        notifyListeners();
      }
    }
  }

  int _calculateFreeSteps(Snake snake) {
    Point dir = _getDirVector(snake.exitDirection);
    Point current = snake.head;
    int steps = 0;
    int limit = 500;

    while (steps < limit) {
      current = current + dir;
      if (!isValid(current)) return 999;

      bool collision = false;
      for (var other in snakes) {
        if (other != snake && !other.isExited && other.body.contains(current)) {
          collision = true;
          break;
        }
      }
      if (collision) break;
      steps++;
    }
    return steps;
  }

  void _animateCollision(Snake snake, int freeSteps, TickerProvider vsync) {
    _animControllers[snake.id]?.dispose();
    double targetDist = freeSteps > 0 ? freeSteps.toDouble() + 0.3 : 0.4;

    final controller = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 500));
    final animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: targetDist), weight: 40),
      TweenSequenceItem(tween: ConstantTween(targetDist), weight: 20),
      TweenSequenceItem(tween: Tween(begin: targetDist, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    bool hasTurnedRed = false;

    animation.addListener(() {
      snake.currentOffset = animation.value;
      if (animation.value >= targetDist * 0.9 && !hasTurnedRed) {
        snake.displayColor = AppColors.collision;
        snake.originalColor = AppColors.collision;
        hasTurnedRed = true;
      }
      notifyListeners();
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        snake.currentOffset = 0.0;
        _animControllers.remove(snake.id);
        controller.dispose();
        notifyListeners();
      }
    });

    _animControllers[snake.id] = controller;
    controller.forward();
  }

  void _animateExit(Snake snake, TickerProvider vsync) {
    if (snake.isExited) return;

    snake.isExited = true;
    SoundManager.play('slide.mp3');
    notifyListeners();

    _animControllers[snake.id]?.dispose();

    final controller = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 800));
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInCubic);

    animation.addListener(() {
      snake.currentOffset = animation.value * (max(rows, cols) + snake.body.length + 2);
      notifyListeners();
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animControllers.remove(snake.id);
        controller.dispose();
        _checkLevelComplete();
      }
    });

    _animControllers[snake.id] = controller;
    controller.forward();
  }

  void _checkLevelComplete() {
    if (snakes.every((s) => s.isExited)) {
      if (!isLevelSuccess) {
        isLevelSuccess = true;
        SoundManager.play('win.mp3');
        notifyListeners();
      }
    }
  }

  void _disposeControllers() {
    for (var c in _animControllers.values) c.dispose();
    _animControllers.clear();
    // _timer?.cancel(); // Timer burada iptal edilmemeli
  }

  @override
  void dispose() {
    _timer?.cancel(); // Timer sadece burada iptal edilmeli
    _disposeControllers();
    super.dispose();
  }
// --- GameController'ın Alt Kısım Bitişi ---
}

// --- 6. OYUN EKRANI ---
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController _controller;
  final TransformationController _transformController = TransformationController();

  bool _isDialogShowing = false;
  bool _shouldCenterBoard = true;
  int _lastLevel = 0;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_onGameUpdate);
  }

  // --- YENİ EKLENDİ: Zorluk seviyesini tercüme eden yardımcı fonksiyon ---
  String _getLocalizedDifficulty(BuildContext context, int level) {
    // Çeviri nesnesini al
    final l10n = AppLocalizations.of(context)!;
    // Level'a göre zorluk indeksini hesapla (Controller'daki mantığın aynısı)
    int difficultyIndex = (level - 1) % 6;

    switch (difficultyIndex) {
      case 0: return l10n.difficultySimple.toUpperCase();
      case 1: return l10n.difficultyEasy.toUpperCase();
      case 2: return l10n.difficultyNormal.toUpperCase();
      case 3: return l10n.difficultyHard.toUpperCase();
      case 4: return l10n.difficultyVeryHard.toUpperCase();
      case 5: return l10n.difficultyNightmare.toUpperCase();
      default: return l10n.difficultyNormal.toUpperCase();
    }
  }

  void _onGameUpdate() {
    if (mounted) {
      setState(() {});
      if (_controller.level != _lastLevel) {
        _lastLevel = _controller.level;
        _shouldCenterBoard = true;
      }
      if (_controller.isLevelSuccess && !_isDialogShowing) {
        _isDialogShowing = true;
        Future.delayed(Duration.zero, () {
          _showLevelCompleteDialog();
        });
      }
      if (!_controller.isLevelSuccess && _isDialogShowing) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _isDialogShowing = false;
      }
    }
  }

  void _showLevelCompleteDialog() {
    // Çeviri nesnesini al
    final l10n = AppLocalizations.of(context)!;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.accent, width: 2)
          ),
          title: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.yellow, size: 60),
              const SizedBox(height: 10),
              // Çevrildi: "LEVEL TAMAMLANDI!"
              Text(l10n.levelCompletedDialogTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Çevrildi: "Süre:"
                        Text(l10n.timeLabel, style: const TextStyle(color: AppColors.textSecondary)),
                        Text(_controller.getFormattedTime(_controller.levelSeconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Çevrildi: "Zorluk:"
                        Text(l10n.difficultyLabel, style: const TextStyle(color: AppColors.textSecondary)),
                        // Çevrildi: Dinamik zorluk etiketi
                        Text(_getLocalizedDifficulty(context, _controller.level), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _isDialogShowing = false;
                  Navigator.pop(ctx);
                  _controller.nextLevel();
                },
                icon: const Icon(Icons.arrow_forward),
                // Çevrildi: "SONRAKİ LEVEL"
                label: Text(l10n.nextLevelButton),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
              ),
            )
          ],
        )
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onGameUpdate);
    _controller.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Çeviri nesnesine erişim
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      bottomNavigationBar: _controller.isGameOver ? null : const RealAdBanner(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildInfoPanel(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double cellSize = 38.0;
                    double boardWidth = _controller.cols * cellSize;
                    double boardHeight = _controller.rows * cellSize;

                    if (_shouldCenterBoard && !_controller.isGenerating) {
                      final double scale = 0.9;
                      final double x = (constraints.maxWidth - (boardWidth * scale)) / 2;
                      final double y = (constraints.maxHeight - (boardHeight * scale)) / 2;

                      _transformController.value = Matrix4.identity()
                        ..translate(x, y)
                        ..scale(scale);

                      Future.microtask(() => setState(() {
                        _shouldCenterBoard = false;
                      }));
                    }

                    return InteractiveViewer(
                      key: ValueKey(_controller.level),
                      transformationController: _transformController,
                      boundaryMargin: const EdgeInsets.all(500.0),
                      minScale: 0.1,
                      maxScale: 4.0,
                      constrained: false,
                      child: GestureDetector(
                        onTapUp: (details) {
                          int tx = (details.localPosition.dx / 38.0).floor();
                          int ty = (details.localPosition.dy / 38.0).floor();
                          _controller.handleTap(Point(tx, ty), this);
                        },
                        child: Container(
                          width: boardWidth,
                          height: boardHeight,
                          color: AppColors.bg,
                          child: CustomPaint(
                            painter: GridAndSnakePainter(
                              snakes: _controller.snakes,
                              rows: _controller.rows,
                              cols: _controller.cols,
                              cellSize: 38.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          if (_controller.showHourWarning)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                // Çevrildi: "1 SAAT OLDU! MOLA VER?"
                child: Text(l10n.hourWarningMessage, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

          if (_controller.isGenerating)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.accent),
                    const SizedBox(height: 20),
                    // Çevrildi: "Level X Hazırlanıyor..." (Parametreli)
                    Text(l10n.loadingLevelMessage(_controller.level), style: const TextStyle(color: Colors.white))
                  ],
                ),
              ),
            ),

          if (_controller.isGameOver)
            Container(
              color: AppColors.collision.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sentiment_very_dissatisfied, color: Colors.white, size: 80),
                    const SizedBox(height: 20),
                    // Çevrildi: "GAME OVER" (veya "OYUN BİTTİ")
                    Text(l10n.gameOverTitle, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 5)),
                    const SizedBox(height: 10),
                    // Çevrildi: "Level X - Süre: XX:XX" (İki parametreli)
                    Text(l10n.gameOverStats(_controller.level, _controller.getFormattedTime(_controller.levelSeconds)), style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        _controller.restartGame();
                      },
                      icon: const Icon(Icons.refresh),
                      // Çevrildi: "BAŞA DÖN"
                      label: Text(l10n.restartButton),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    // Çeviri nesnesine erişim
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Çevrildi: "LEVEL X" (Parametreli)
                  Text(l10n.panelLevelTitle(_controller.level), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  // Çevrildi: Dinamik zorluk etiketi
                  Text(_getLocalizedDifficulty(context, _controller.level), style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ],
              ),
              _buildStatCard(
                  icon: Icons.timer,
                  // Çevrildi: "TOPLAM"
                  label: l10n.statTotal,
                  value: _controller.getFormattedTime(_controller.totalSeconds),
                  color: Colors.blueAccent
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                  icon: Icons.watch_later_outlined,
                  // Çevrildi: "SÜRE"
                  label: l10n.statTime,
                  value: _controller.getFormattedTime(_controller.levelSeconds),
                  color: Colors.white70
              ),
              _buildStatCard(
                  icon: Icons.grid_on,
                  // Çevrildi: "KALAN"
                  label: l10n.statRemaining,
                  value: "${_controller.remainingSnakes}",
                  color: AppColors.success
              ),
              Row(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      index < _controller.lives ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.collision,
                      size: 24,
                    ),
                  );
                }),
              ),
              IconButton(onPressed: _controller.startNewLevel, icon: const Icon(Icons.refresh, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1))
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

// --- 7. ÇİZİM (Değişiklik Yok) ---
class GridAndSnakePainter extends CustomPainter {
  final List<Snake> snakes;
  final int rows;
  final int cols;
  final double cellSize;

  GridAndSnakePainter({
    required this.snakes,
    required this.rows,
    required this.cols,
    required this.cellSize
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, cols * cellSize, rows * cellSize));

    final cellW = cellSize;
    final cellH = cellSize;

    final dotPaint = Paint()..color = AppColors.gridDot;
    for (int y = 0; y <= rows; y++) {
      for (int x = 0; x <= cols; x++) {
        if (x < cols && y < rows) {
          canvas.drawCircle(Offset((x + 0.5) * cellW, (y + 0.5) * cellH), 1.5, dotPaint);
        }
      }
    }

    for (var snake in snakes) {
      if (snake.isExited && snake.currentOffset > (max(rows, cols) + snake.body.length + 5)) continue;

      final snakeWidth = 6.0;

      final paint = Paint()
        ..color = snake.displayColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = snakeWidth;

      Path snakePath = Path();
      double totalSegments = (snake.body.length - 1).toDouble();
      double startDist = snake.currentOffset;
      double endDist = startDist + totalSegments;

      List<Offset> drawPoints = [];
      for (double d = startDist; d <= endDist + 0.05; d += 0.1) {
        if (d > endDist) d = endDist;
        drawPoints.add(_getPointOnSnakePath(snake, d, cellW, cellH));
        if (d == endDist) break;
      }

      if (drawPoints.isNotEmpty) {
        snakePath.moveTo(drawPoints[0].dx, drawPoints[0].dy);
        for(int i=1; i<drawPoints.length; i++) {
          snakePath.lineTo(drawPoints[i].dx, drawPoints[i].dy);
        }

        canvas.drawPath(snakePath, Paint()
          ..color = snake.displayColor.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = snakeWidth * 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        );

        canvas.drawPath(snakePath, paint);

        Offset headPos = drawPoints.last;
        _drawArrow(canvas, headPos, snake.exitDirection, 7.0, snake.displayColor);
      }
    }

    final borderPaint = Paint()
      ..color = AppColors.gridDot.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, cols * cellSize, rows * cellSize), borderPaint);

    canvas.restore();
  }

  Offset _getPointOnSnakePath(Snake snake, double distance, double cellW, double cellH) {
    int segmentIndex = distance.floor();
    double t = distance - segmentIndex;

    Point p1, p2;

    if (segmentIndex < snake.body.length - 1) {
      p1 = snake.body[segmentIndex];
      p2 = snake.body[segmentIndex + 1];
    }
    else {
      Point lastReal = snake.body.last;
      int extraSteps = segmentIndex - (snake.body.length - 1);
      Point dirVec;
      switch (snake.exitDirection) {
        case Direction.up: dirVec = const Point(0, -1); break;
        case Direction.down: dirVec = const Point(0, 1); break;
        case Direction.left: dirVec = const Point(-1, 0); break;
        case Direction.right: dirVec = const Point(1, 0); break;
      }
      p1 = lastReal + (dirVec * extraSteps);
      p2 = lastReal + (dirVec * (extraSteps + 1));
    }

    double x1 = (p1.x + 0.5) * cellW;
    double y1 = (p1.y + 0.5) * cellH;
    double x2 = (p2.x + 0.5) * cellW;
    double y2 = (p2.y + 0.5) * cellH;

    return Offset(
      x1 + (x2 - x1) * t,
      y1 + (y2 - y1) * t,
    );
  }

  void _drawArrow(Canvas canvas, Offset center, Direction dir, double size, Color color) {
    final paint = Paint()..color = color == AppColors.collision ? color : Colors.white..style = PaintingStyle.fill;
    Path p = Path();
    double s = size * 0.6;
    Offset c = center;
    double push = size * 0.5;

    switch (dir) {
      case Direction.up:    c += Offset(0, -push); p.moveTo(c.dx, c.dy - s); p.lineTo(c.dx - s, c.dy + s); p.lineTo(c.dx + s, c.dy + s); break;
      case Direction.down:  c += Offset(0, push); p.moveTo(c.dx, c.dy + s); p.lineTo(c.dx - s, c.dy - s); p.lineTo(c.dx + s, c.dy - s); break;
      case Direction.left:  c += Offset(-push, 0); p.moveTo(c.dx - s, c.dy); p.lineTo(c.dx + s, c.dy - s); p.lineTo(c.dx + s, c.dy + s); break;
      case Direction.right: c += Offset(push, 0); p.moveTo(c.dx + s, c.dy); p.lineTo(c.dx - s, c.dy - s); p.lineTo(c.dx - s, c.dy + s); break;
    }
    p.close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant GridAndSnakePainter oldDelegate) => true;
}