import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:new_barfit/models/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_barfit/services/mode_repository.dart';

import 'profile_screen.dart';
import 'three_screen.dart';
import 'two_screen.dart';

void main() {
  runApp(MaterialApp(home: OneScreen()));
}

class OneScreen extends StatefulWidget {
  const OneScreen({super.key});

  @override
  _OneScreenState createState() => _OneScreenState();
}

class _OneScreenState extends State<OneScreen> {
  Timer? _sharedTimerListener;

  int _goalMinutes = 30;
  String? _userName, _userLastName, _currentTip;
  int _sharedTimerSeconds = 0;
  DateTime? _firstSessionDate;
  Map<String, dynamic>? _selectedMode;

  final List<String> _tips = [
    'Разогревайся перед каждой тренировкой.',
    'Делай заминку после тренировки.',
    'Работай с прогрессивной нагрузкой.',
    'Следи за техникой выполнения упражнений.',
    'Не забывай про растяжку.',
    'Не пропускай тренировки.',
    'Следи за дыханием во время упражнений.',
    'Комбинируй силовые и кардио нагрузки.',
    'Тренируй мышцы антагонисты (бицепс/трицепс, грудь/спина).',
    'Работай с разными диапазонами повторений.',
    'Используй суперсеты для повышения интенсивности.',
    'Добавляй дроп-сеты для шокирования мышц.',
    'Меняй программу раз в 6-8 недель.',
    'Используй периодизацию нагрузок.',
    'Работай над мобильностью суставов.',
    'Не тренируйся до изнеможения каждый день.',
    'Увеличивай нагрузку постепенно.',
    'Уделяй внимание технике, а не весу.',
    'Тренируй все группы мышц равномерно.',
    'Работай над осанкой.',
    'Спи не менее 7-9 часов в день.',
    'Давай мышцам отдых после тяжелых тренировок.',
    'Используй массажный ролик для восстановления.',
    'Делай контрастный душ после тренировок.',
    'Уменьши уровень стресса.',
    'Следи за уровнем витаминов и минералов.',
    'Пей достаточно воды.',
    'Избегай обезвоживания.',
    'Следи за уровнем железа, особенно если чувствуешь усталость.',
    'Дыши глубже во время тренировок и в повседневной жизни.',
    'Следи за уровнем кортизола.',
    'Избегай частых ночных перекусов.',
    'Давай отдых не только телу, но и нервной системе.',
    'Избегай чрезмерного употребления алкоголя.',
    'Уменьши потребление сахара.',
    'Проверяй уровень гормонов при длительном упадке сил.',
    'Делай перерывы в тренировках при болезни.',
    'Не злоупотребляй стимуляторами перед тренировками.',
    'Уменьши употребление кофеина, если нарушен сон.',
    'Избегай долгого сидячего положения.',
    'Ешь больше белка для роста мышц.',
    'Потребляй сложные углеводы перед тренировкой.',
    'Употребляй полезные жиры для гормонального здоровья.',
    'Увеличивай количество овощей в рационе.',
    'Следи за количеством клетчатки.',
    'Ешь больше цельных продуктов.',
    'Следи за балансом БЖУ.',
    'Избегай переедания.',
    'Не злоупотребляй фастфудом.',
    'Следи за уровнем сахара в крови.',
    'Ешь медленно, чтобы избежать переедания.',
    'Используй пищевой дневник для контроля рациона.',
    'Ешь больше рыбы для здоровья сердца.',
    'Пей больше воды вместо сладких напитков.',
    'Завтракай правильно: белки + полезные жиры.',
    'Готовь еду заранее, чтобы не срываться на вредную пищу.',
    'Ешь после тренировки для восстановления мышц.',
    'Контролируй потребление соли.',
    'Питайся разнообразно.',
    'Не исключай углеводы полностью.',
    'Добавь кардио для укрепления сердца.',
    'Меняй интенсивность кардио для лучшего эффекта.',
    'Делай кардио натощак, если цель – жиросжигание.',
    'Используй интервальные тренировки.',
    'Не забывай про плавание для щадящей нагрузки.',
    'Не делай слишком много кардио, если цель – набор массы.',
    'Используй ходьбу как дополнительное кардио.',
    'Включай беговые тренировки раз в неделю.',
    'Добавляй спринты для ускорения метаболизма.',
    'Кардио можно заменять активными играми.',
    'Развивай гибкость для лучшего прогресса в силовых.',
    'Используй статическую и динамическую растяжку.',
    'Делай упражнения на баланс.',
    'Используй йогу или пилатес для восстановления.',
    'Работай над подвижностью суставов.',
    'Уделяй внимание стопам и их укреплению.',
    'Развивай чувство тела в пространстве.',
    'Не игнорируй растяжку спины.',
    'Работай над координацией движений.',
    'Делай упражнения босиком для укрепления стоп.',
    'Ставь четкие цели в тренировках.',
    'Не сравнивай себя с другими.',
    'Записывай прогресс.',
    'Найди приятную музыку для тренировок.',
    'Делай фото до/после для мотивации.',
    'Следи за своими успехами, а не чужими.',
    'Тренируйся для себя, а не ради чужого мнения.',
    'Найди партнера для тренировок.',
    'Пробуй новые виды спорта.',
    'Чередуй тренировки, чтобы избежать скуки.',
    'Не зацикливайся на весах, следи за объемами.',
    'Добавляй активность в повседневную жизнь.',
    'Используй лестницы вместо лифта.',
    'Не пропускай разминку, даже если мало времени.',
    'Меняй программы тренировок каждые 2-3 месяца.',
    'Дыши правильно во время упражнений.',
    'Прислушивайся к своему телу.',
    'Умей отдыхать без чувства вины.',
    'Следи за осанкой не только в зале, но и в жизни.',
    'Получай удовольствие от тренировок!',
  ];

  Map<String, int> _historyByDay = {};

  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAndCheckDate();
    _startSharedTimerListener();
    // Listen for active mode changes so the blue card updates immediately when
    // another screen (Modes/Settings) marks a mode as active/favorite.
    ModeRepository.activeModeNotifier.addListener(_onActiveModeChanged);
  }

  @override
  void dispose() {
    _sharedTimerListener?.cancel();
    _historyScrollController.dispose();
    ModeRepository.activeModeNotifier.removeListener(_onActiveModeChanged);
    super.dispose();
  }

  void _onActiveModeChanged() {
    final newMode = ModeRepository.activeModeNotifier.value;
    if (!mounted) return;
    setState(() {
      _selectedMode = newMode;
    });
  }

  Future<void> _initializeAndCheckDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenDateStr = prefs.getString('lastOpenDate');
    final now = DateTime.now();
    // Устанавливаем время на 00:00:00 для корректного сравнения дат
    final today = DateTime(now.year, now.month, now.day);

    if (lastOpenDateStr != null) {
      final lastOpenDate = DateTime.parse(lastOpenDateStr);
      // Проверяем, наступил ли новый день с последнего открытия приложения
      if (lastOpenDate.isBefore(today)) {
        // Если да, то сохраняем время тренировки за прошлый день
        final secondsFromLastDay = prefs.getInt('sharedTimer') ?? 0;

        // Сохраняем, только если было потрачено время (> 0 секунд)
        if (secondsFromLastDay > 0) {
          final historyString = prefs.getString('historyByDay') ?? '{}';
          final history = Map<String, int>.from(jsonDecode(historyString));

          // Создаем ключ в формате YYYY-MM-DD для консистентности
          final key = "${lastOpenDate.year}-${lastOpenDate.month.toString().padLeft(2, '0')}-${lastOpenDate.day.toString().padLeft(2, '0')}";
          history[key] = (history[key] ?? 0) + secondsFromLastDay;
          
          await prefs.setString('historyByDay', jsonEncode(history));
        }

        // Сбрасываем таймер для нового дня
        await prefs.setInt('sharedTimer', 0);
      }
    }

    // Обновляем дату последнего открытия на сегодня
    await prefs.setString('lastOpenDate', today.toIso8601String());

    await _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      final selectedModeString = prefs.getString('favorite_mode');
      if (selectedModeString != null) {
        _selectedMode = jsonDecode(selectedModeString);
      } else {
        _selectedMode = null;
      }

      _userName = prefs.getString('userName');
      _userLastName = prefs.getString('userLastName');
      _goalMinutes = prefs.getInt('goalMinutes') ?? 30;
      _currentTip = _generateRandomTip();
      final firstDateStr = prefs.getString('firstSessionDate');
      if (firstDateStr != null) {
        _firstSessionDate = DateTime.tryParse(firstDateStr);
      }
    });

    if (_firstSessionDate == null) {
      final now = DateTime.now();
      _firstSessionDate = now;
      await prefs.setString('firstSessionDate', now.toIso8601String());
    }
    if (_userName == null || _userLastName == null) _showNameInputDialog();
    _loadHistoryByDay();
  }

  String _generateRandomTip() {
    final random = Random();
    return _tips[random.nextInt(_tips.length)];
  }

  bool _isNameDialogShowing = false;

  void _showNameInputDialog() async {
    if (_isNameDialogShowing) return;
    setState(() {
      _isNameDialogShowing = true;
    });

    final nameController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Добро пожаловать!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blue),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Пожалуйста, введите ваше имя',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Ваше имя',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _saveUserName(nameController.text, '');
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() {
        _isNameDialogShowing = false;
      });
    }
  }

  Future<void> _saveUserName(String firstName, String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', firstName);
    await prefs.setString('userLastName', lastName);
    setState(() {
      _userName = firstName;
      _userLastName = lastName;
    });
  }

  void _startSharedTimerListener() {
    _sharedTimerListener = Timer.periodic(const Duration(seconds: 1), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt('sharedTimer') ?? 0;

      if (mounted && seconds != _sharedTimerSeconds) {
        setState(() {
          _sharedTimerSeconds = seconds;
        });

        // Сохраняем прогресс текущего дня в историю "вживую"
                                final now = DateTime.now();
                                final todayKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        
        final historyString = prefs.getString('historyByDay') ?? '{}';
        final history = Map<String, int>.from(jsonDecode(historyString));
        
        history[todayKey] = seconds;
        
        // Если за день ничего не было, удаляем ключ, чтобы не показывать "Пн: 0 сек"
        if (seconds == 0) {
          history.remove(todayKey);
        }
        
        await prefs.setString('historyByDay', jsonEncode(history));
        
        if (mounted) {
          setState(() {
            _historyByDay = history;
          });
        }
      }
    });
  }

  // Removed unused helpers: _resetSharedTimer, _daysSinceFirstSession, _weeksSinceFirstSession

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds.toString().padLeft(2, '0')} сек';
    } else if (seconds < 3600) {
      final int minutes = seconds ~/ 60;
      final int remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      final int hours = seconds ~/ 3600;
      final int minutes = (seconds % 3600) ~/ 60;
      final int remainingSeconds = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatDayTime(int seconds) {
    if (seconds < 60) {
      return '$seconds сек';
    } else if (seconds < 3600) {
      final int minutes = seconds ~/ 60;
      return '$minutes мин';
    } else {
      final int hours = seconds ~/ 3600;
      final int minutes = (seconds % 3600) ~/ 60;
      return '$hours ч $minutes мин';
    }
  }

  Future<void> _loadHistoryByDay() async {
    final prefs = await SharedPreferences.getInstance();
    final mapString = prefs.getString('historyByDay');
    if (mapString != null && mapString.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(mapString);
        final Map<String, int> history = {};
        decoded.forEach((key, value) {
          if (value is int) {
            history[key] = value;
          } else if (value is String) {
            history[key] = int.tryParse(value) ?? 0;
          } else if (value is double) {
            history[key] = value.toInt();
          }
        });
        if (mounted) {
          setState(() {
            _historyByDay = history;
          });
        }
      } catch (e) {
        print("Error decoding historyByDay: $e");
        // Handle error, maybe clear the corrupted history
        await prefs.remove('historyByDay');
        if (mounted) {
          setState(() {
            _historyByDay = {};
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _historyByDay = {};
        });
      }
    }
  }

  // _saveHistoryByDay removed (unused)

  String _normalizeDateKey(String key) {
  final parts = key.split('-');
  if (parts.length == 3) {
    final year = parts[0];
    final month = parts[1].padLeft(2, '0');
    final day = parts[2].padLeft(2, '0');
    return '$year-$month-$day';
  }
  return key;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            if (index == 1) {
              _currentTip = _generateRandomTip();
              _loadData();
            }
            _currentPage = index;
          });
        },
        children: [
          ProfileScreen(),
          _buildMainContent(context),
          TwoScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
        child: Container(
          height: 80,
          width: 370,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  _pageController.jumpToPage(0);
                },
                child: Icon(Icons.account_circle_outlined,
                    color: _currentPage == 0 ? Colors.blue : Colors.black, size: 48),
              ),
              GestureDetector(
                onTap: () {
                  _pageController.jumpToPage(1);
                },
                child: Icon(Icons.home,
                    color: _currentPage == 1 ? Colors.blue : Colors.black, size: 48),
              ),
              GestureDetector(
                onTap: () {
                  _pageController.jumpToPage(2);
                },
                child: Icon(Icons.settings,
                      color: _currentPage == 2 ? Colors.blue : Colors.black, size: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ПРИВЕТ, ${_userName?.toUpperCase() ?? 'ГОСТЬ'} ${_userLastName?.toUpperCase() ?? ''}.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text('ГОТОВ К НОВОЙ',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('ТРЕНИРОВКЕ?',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GestureDetector(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 155,
                width: 370,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.18),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сегодня',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Builder(builder: (context) {
                              if (_userName == null || _userLastName == null) {
                                return const Text(
                                  'Нет истории тренировок',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                );
                              }
                              final now = DateTime.now();
                              final todayKey = _normalizeDateKey("${now.year}-${now.month}-${now.day}");
                final today =
                  DateTime(now.year, now.month, now.day);
                final yesterday =
                  today.subtract(const Duration(days: 1));
                // startOfWeek removed (was unused)

                              final sortedHistory =
                              _historyByDay.entries
                                    .where((entry) => _normalizeDateKey(entry.key) != todayKey)
                                    .toList()
                                    ..sort((a, b) {
                                      final dateA = DateTime.tryParse(_normalizeDateKey(a.key));
                                      final dateB = DateTime.tryParse(_normalizeDateKey(b.key));
                                      if (dateA == null || dateB == null)
                                        return 0;
                                      return dateB.compareTo(dateA);
                                    });

                              return Scrollbar(
                                controller: _historyScrollController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: _historyScrollController,
                                  padding: EdgeInsets.zero,
                                  itemCount: sortedHistory.length,
                                  itemBuilder: (context, index) {
                                    final entry = sortedHistory[index];
                                    final normalizedKey = _normalizeDateKey(entry.key);
                                    final date = DateTime.tryParse(normalizedKey);
                                    String label;
                                    if (date != null) {
                                      final entryDate = DateTime(
                                          date.year, date.month, date.day);
                                      if (entryDate == yesterday) {
                                        label = 'Вчера';
                                      } else {
                                        label = [
                                          'Понедельник',
                                          'Вторник',
                                          'Среда',
                                          'Четверг',
                                          'Пятница',
                                          'Суббота',
                                          'Воскресенье'
                                        ][date.weekday - 1];
                                      }
                                    } else {
                                      label = entry.key;
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 2, right: 8),
                                      child: Text(
                                        '$label: ${_formatDayTime(entry.value)}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(100, 100),
                              painter: CircleProgressPainter(
                                progress: (_goalMinutes * 60) > 0
                                    ? (_sharedTimerSeconds / (_goalMinutes * 60))
                                        .clamp(0.0, 1.0)
                                    : 0,
                                backgroundColor: Colors.grey.shade200,
                                progressGradient: const SweepGradient(
                                  transform: GradientRotation(-pi / 2),
                                  colors: [Colors.blue, Colors.blue],
                                ),
                                strokeWidth: 18,
                              ),
                            ),
                            Text(
                              _formatTime(_sharedTimerSeconds),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 155,
              width: 370,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context, MaterialPageRoute(builder: (context) => const ThreeScreen(isStandardMode: true, startFresh: true)),
                        ).then((_) => _loadData());
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: const [
                            Text('Таймер',
                                  style: TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreeScreen(
                            initialMode: _selectedMode),
                      ),
                    ).then((_) => _loadData()),
                    child: Container(
                      height: 108,
                      width: 108,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(15)),
                      child: _selectedMode != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  AppIcons.fromCodePoint(_selectedMode!['icon'] as int? ?? Icons.timer.codePoint),
                                  size: 40,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedMode!['modeName'] as String? ??
                                      'Таймер',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.emoji_events_outlined,
                                    size: 40, color: Colors.white),
                                SizedBox(height: 4),
                                Text(
                                  'Режим победителя',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 88,
              width: 370,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.18),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 67,
                      color: Colors.blue,
                      child: Center(
                        child: Icon(Icons.lightbulb, color: Colors.white, size: 30),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: Text(
                            _currentTip ?? 'Загрузка совета...',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Gradient progressGradient;
  final double strokeWidth;

  CircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressGradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..shader = progressGradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double angle = 2 * pi * progress;
    canvas.drawArc(rect, -pi / 2, angle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}