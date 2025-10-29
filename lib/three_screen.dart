import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'modes_screen.dart';
import 'one_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_barfit/services/mode_repository.dart';
// Constants for SharedPreferences keys
const String _kStandardTimerStateKey = 'standard_timer_state';
const String _kLastNamedTimerStateKey = 'last_named_timer_state';

class ThreeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMode;
  final bool isStandardMode;
  final bool startFresh;

  const ThreeScreen({
    Key? key,
    this.initialMode,
    this.isStandardMode = false,
    this.startFresh = false,
  }) : super(key: key);

  @override
  _ThreeScreenState createState() => _ThreeScreenState();
}

class _ThreeScreenState extends State<ThreeScreen> with WidgetsBindingObserver {
  Future<void> _loadModesFromRepository() async {
    if (!mounted) return;
    try {
      final loaded = await ModeRepository.loadSavedModes();
      if (!mounted) return;
      setState(() {
        savedModes = loaded;
      });
    } catch (e) {
      setState(() {
        savedModes = [];
      });
    }
  }
  int totalExercises = 5,
      exerciseDuration = 30,
      exerciseBreak = 10,
      roundDuration = 5,
      roundBreak = 30;
  int currentExercise = 1, currentRound = 1, remainingTime = 30, totalTime = 30;
  Timer? timer;
  bool isRunning = false,
      isBreakTime = false,
      isSaved = false,
      isRoundBreakTime = false;
  String modeName = 'Таймер';
  List<Map<String, dynamic>> savedModes = [];
  String selectedMelody = 'assets/sounds/002.mp3'; // Default melody
  final AudioPlayer _melodyPlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();

  int sessionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentModeName();
    WidgetsBinding.instance.addObserver(this);
    // Load saved modes first, as they might be needed during initialization
    _loadModesFromPrefs().then((_) {
      _initializeState();
    });
  }

  Future<void> _loadCurrentModeName() async {
    final prefs = await SharedPreferences.getInstance();
    final String savedModeName = prefs.getString('currentModeName') ?? 'Режим по умолчанию';
    setState(() {
      modeName = savedModeName; // assign to the class field
    });
  }

  void _showResumeDialog(Map<String, dynamic> pausedState) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Незавершенная тренировка",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Хотите продолжить с того места, где остановились, или начать заново?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    "Продолжить",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applyState(pausedState);
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    "Начать заново",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final prefs = await SharedPreferences.getInstance();

                    final String currentModeName = pausedState['modeName'] ?? 'Таймер';
                    final modeSpecificKey = 'timer_state_$currentModeName';

                    await prefs.remove(modeSpecificKey);
                    await prefs.remove(_kLastNamedTimerStateKey);
                    
                    if (widget.initialMode != null) {
                      loadMode(widget.initialMode!);
                    } else {
                      await _loadSettings();
                      setState(() {
                        modeName = 'Таймер';
                        currentExercise = 1;
                        currentRound = 1;
                        remainingTime = exerciseDuration;
                        isBreakTime = false;
                        isRoundBreakTime = false;
                        sessionSeconds = 0;
                        isRunning = false;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Central dispatcher for loading the correct state
  Future<void> _initializeState() async {
    final prefs = await SharedPreferences.getInstance();
  
    if (widget.startFresh == true) {
      await prefs.remove(_kLastNamedTimerStateKey);
      await prefs.remove(_kStandardTimerStateKey);
      if (widget.initialMode != null) {
        final modeNameForKey = widget.initialMode!['modeName'] ?? widget.initialMode!['name'] ?? 'Таймер';
        final modeSpecificKey = 'timer_state_$modeNameForKey';
        await prefs.remove(modeSpecificKey);
      }
    }
  
    String currentModeName = 'Таймер';
    if (widget.initialMode != null) {
      currentModeName = widget.initialMode!['modeName'] ?? widget.initialMode!['name'] ?? 'Таймер';
    }

    if (widget.isStandardMode) {
      await _loadStandardState();
    } else {
      // Try to load mode-specific state first
      final modeSpecificKey = 'timer_state_$currentModeName';
      final modeStateString = prefs.getString(modeSpecificKey);

      if (modeStateString != null && widget.startFresh == false) {
        final pausedState = jsonDecode(modeStateString);
        final pausedAtString = pausedState['pausedAt'];
        if (pausedAtString != null) {
          final pausedAt = DateTime.parse(pausedAtString);
          final difference = DateTime.now().difference(pausedAt);

          if (difference.inMinutes < 20) {
            _applyState(pausedState);
          } else if (difference.inHours <= 24) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showResumeDialog(pausedState);
              }
            });
          } else {
            await prefs.remove(modeSpecificKey);
            if (widget.initialMode != null) loadMode(widget.initialMode!); else await _loadSettings();
          }
        } else {
          await prefs.remove(modeSpecificKey);
          if (widget.initialMode != null) loadMode(widget.initialMode!); else await _loadSettings();
        }
      } else {
        // Fallback to global last named state
        final stateString = prefs.getString(_kLastNamedTimerStateKey);

        if (stateString != null && widget.startFresh == false) {
          final pausedState = jsonDecode(stateString);
          final pausedAtString = pausedState['pausedAt'];
          if (pausedAtString != null) {
            final pausedAt = DateTime.parse(pausedAtString);
            final difference = DateTime.now().difference(pausedAt);

            if (difference.inMinutes < 20) {
              _applyState(pausedState);
            } else if (difference.inHours <= 24) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showResumeDialog(pausedState);
                }
              });
            } else {
              await prefs.remove(_kLastNamedTimerStateKey);
              if (widget.initialMode != null) loadMode(widget.initialMode!); else await _loadSettings();
            }
          } else {
            await prefs.remove(_kLastNamedTimerStateKey);
            if (widget.initialMode != null) loadMode(widget.initialMode!); else await _loadSettings();
          }
                } else if (widget.initialMode != null) {
                  _applyState(widget.initialMode!); // Apply state directly from initialMode
                } else {          await _loadSettings();
        }
      }
    }
  }

@override
void didChangeAppLifecycleState(AppLifecycleState state) async {
  if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
    await _saveCurrentState();
  }
}

@override
void dispose() {
  // Ожидаем завершения сохранения перед завершением dispose
  _saveCurrentState().whenComplete(() {
    timer?.cancel();
    _melodyPlayer.dispose();
    _tickPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  });
}

  // Central dispatcher for saving the correct state
  Future<void> _saveCurrentState() async {
    if (widget.isStandardMode) {
      await _saveStandardState();
    } else {
      // It's a named mode
      await _saveNamedState();
    }
  }

  // --- State Loading Logic ---

  Future<void> _loadStandardState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_kStandardTimerStateKey);
    if (stateString != null) {
      _applyState(jsonDecode(stateString));
    } else {
      _resetToStandardDefaults();
    }
  }

  // _loadLastNamedState removed (unused)

  // --- State Saving Logic ---

  Future<void> _saveStandardState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentState = _getCurrentStateAsMap();
    await prefs.setString(_kStandardTimerStateKey, jsonEncode(currentState));
  }

  Future<void> _saveNamedState() async {
    final prefs = await SharedPreferences.getInstance();
    final currentState = _getCurrentStateAsMap();
    currentState['pausedAt'] = DateTime.now().toIso8601String();

    // Сохраняем в ключ для последнего сохранённого состояния
    await prefs.setString(_kLastNamedTimerStateKey, jsonEncode(currentState));

    // Также сохраняем для конкретного режима, если это не стандартный таймер
    if (modeName != 'Таймер' && modeName != 'Стандартный режим') {
      final modeSpecificKey = 'timer_state_$modeName';
      await prefs.setString(modeSpecificKey, jsonEncode(currentState));
    }

    // Обновляем прогресс в списке сохранённых режимов
    final index = savedModes.indexWhere((m) => (m['modeName'] ?? m['name']) == modeName);
    if (index != -1) {
      setState(() {
        savedModes[index] = {
          ...savedModes[index],
          ...currentState,
        };
      });
      await _saveModes();
    }
  }

  // --- Resetting and Helper Logic ---

  void _resetToStandardDefaults() {
    setState(() {
      exerciseDuration = 30;
      exerciseBreak = 10;
      totalExercises = 5;
      roundDuration = 5;
      roundBreak = 30;
      modeName = 'Стандартный режим';
      
      // Reset progress
      isRunning = false;
      isSaved = false;
      currentExercise = 1;
      currentRound = 1;
      remainingTime = exerciseDuration;
      totalTime = exerciseDuration;
      isBreakTime = false;
      isRoundBreakTime = false;
      sessionSeconds = 0;
    });
    timer?.cancel();
  }

  Map<String, dynamic> _getCurrentStateAsMap() {
    return {
      'totalExercises': totalExercises,
      'exerciseDuration': exerciseDuration,
      'exerciseBreak': exerciseBreak,
      'roundDuration': roundDuration,
      'roundBreak': roundBreak,
      'currentExercise': currentExercise,
      'currentRound': currentRound,
      'remainingTime': remainingTime,
      'isBreakTime': isBreakTime,
      'isRoundBreakTime': isRoundBreakTime,
      'sessionSeconds': sessionSeconds,
      'isRunning': isRunning,
      'modeName': modeName,
    };
  }

  void _applyState(Map<String, dynamic> state) {
    setState(() {
      totalExercises = state['totalExercises'] ?? 5;
      exerciseDuration = state['exerciseDuration'] ?? 30;
      exerciseBreak = state['exerciseBreak'] ?? 10;
      roundDuration = state['roundDuration'] ?? 5;
      roundBreak = state['roundBreak'] ?? 30;
      currentExercise = state['currentExercise'] ?? 1;
      currentRound = state['currentRound'] ?? 1;
      remainingTime = state['remainingTime'] ?? exerciseDuration;
      isBreakTime = state['isBreakTime'] ?? false;
      isRoundBreakTime = state['isRoundBreakTime'] ?? false;
      sessionSeconds = state['sessionSeconds'] ?? 0;
      modeName = state['modeName'] ?? 'Таймер';
      
      // IMPORTANT: We load the isRunning state, but we don't auto-start the timer.
      // The user must press play to resume.
      isRunning = state['isRunning'] ?? false;

      if (isBreakTime) {
        totalTime = isRoundBreakTime ? roundBreak : exerciseBreak;
      } else {
        totalTime = exerciseDuration;
      }
    });
    // If the loaded state was running, immediately pause it.
    if (isRunning) {
      pauseTimer();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // First, try to load from active_mode_for_threescreen
    final activeModeString = prefs.getString('active_mode_for_threescreen');
    if (activeModeString != null) {
      final activeMode = jsonDecode(activeModeString) as Map<String, dynamic>;
      setState(() {
        totalExercises = activeMode['totalExercises'] ?? 5;
        exerciseDuration = activeMode['exerciseDuration'] ?? 30;
        exerciseBreak = activeMode['exerciseBreak'] ?? 10;
        roundDuration = activeMode['roundDuration'] ?? 5;
        roundBreak = activeMode['roundBreak'] ?? 30;
        remainingTime = exerciseDuration;
        totalTime = exerciseDuration;
        selectedMelody = prefs.getString('selectedMelody') ?? 'assets/sounds/002.mp3';
      });
    } else {
      // Fallback to global settings
      setState(() {
        totalExercises = prefs.getInt('exerciseCount') ?? 5;
        exerciseDuration = prefs.getInt('exerciseDuration') ?? 30;
        exerciseBreak = prefs.getInt('exerciseBreak') ?? 10;
        roundDuration = prefs.getInt('roundCount') ?? 5;
        roundBreak = prefs.getInt('roundBreak') ?? 30;
        remainingTime = exerciseDuration;
        totalTime = exerciseDuration;
        selectedMelody = prefs.getString('selectedMelody') ?? 'assets/sounds/002.mp3';
      });
    }
  }

  Future<void> _loadModesFromPrefs() async {
    if (!mounted) return;
    try {
      final loaded = await ModeRepository.loadSavedModes();
      if (!mounted) return;
      setState(() {
        savedModes = loaded;
      });
    } catch (e) {
      // Fallback to previous behavior if repository fails
      final prefs = await SharedPreferences.getInstance();
      final newSavedModes = (prefs.getStringList('savedModes') ?? [])
          .map((e) => Map<String, dynamic>.from(jsonDecode(e)))
          .toList();
      setState(() {
        savedModes = newSavedModes;
      });
    }
  }

  Future<void> _saveModes() async {
    // Persist savedModes via ModeRepository and reload the canonical deduplicated list.
    try {
      await ModeRepository.saveSavedModes(savedModes);
      final cleaned = await ModeRepository.loadSavedModes();
      if (!mounted) return;
      setState(() {
        savedModes = cleaned;
      });
    } catch (e) {
      // Fallback: write directly to prefs if repository fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('savedModes', savedModes.map((e) => jsonEncode(e)).toList());
    }
  }

  // --- Timer Actions ---

  void startTimer() {
    setState(() {
      isRunning = true;
      isSaved = false;
    });
    timer?.cancel();
    int expectedTotalDuration;
    if (isBreakTime) {
      expectedTotalDuration = isRoundBreakTime ? roundBreak : exerciseBreak;
    } else {
      expectedTotalDuration = exerciseDuration;
    }

    if (remainingTime == 0 || remainingTime == expectedTotalDuration) {
        totalTime = expectedTotalDuration;
        remainingTime = totalTime;
    } else {
        totalTime = expectedTotalDuration;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (remainingTime > 0) {
        if (remainingTime <= 5) {
          if (remainingTime == 5) {
            try {
              await _melodyPlayer.play(AssetSource(selectedMelody));
            } catch (e) {
              print('Ошибка воспроизведения мелодии: $e');
            }
          }
        }

        final prefs = await SharedPreferences.getInstance();
        final currentTotal = prefs.getInt('sharedTimer') ?? 0;
        await prefs.setInt('sharedTimer', currentTotal + 1);
        if (mounted) {
          setState(() {
            remainingTime--;
            sessionSeconds++;
          });
        }
      } else {
        await _melodyPlayer.stop();
        if (isBreakTime) {
          nextExerciseOrRound();
        } else { // An exercise just finished
          if (currentExercise == totalExercises) { // Last exercise of the round
            if (currentRound < roundDuration) { // Not the last round
              setState(() {
                isRoundBreakTime = true;
              });
              startBreak(); // Start round break
            } else { // Last exercise of last round
              timer.cancel();
              resetTimer();
            }
          } else { // Not the last exercise
            startBreak(); // Start exercise break
          }
        }
      }
    });
  }

  void stopTimer() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.isStandardMode) {
      await prefs.remove(_kStandardTimerStateKey);
      _resetToStandardDefaults();
    } else {
      // It's a named mode. Reset its progress in the savedModes list.
      final index = savedModes.indexWhere((m) => (m['modeName'] ?? m['name']) == modeName);
      if (index != -1) {
        setState(() {
          savedModes[index]['currentExercise'] = 1;
          savedModes[index]['currentRound'] = 1;
          savedModes[index]['remainingTime'] = savedModes[index]['exerciseDuration'];
          savedModes[index]['isBreakTime'] = false;
          savedModes[index]['isRoundBreakTime'] = false;
          savedModes[index]['sessionSeconds'] = 0;
          savedModes[index]['isRunning'] = false;
        });
        await _saveModes();
      }
      // Reset the view to the default timer settings and clear the last named state
      if (modeName != 'Таймер' && modeName != 'Стандартный режим') {
        final modeSpecificKey = 'timer_state_$modeName';
        await prefs.remove(modeSpecificKey);
      }
      await prefs.remove(_kLastNamedTimerStateKey);
      await _loadSettings(); // Resets to default settings
      // Do not reset modeName here, keep it as loaded from prefs
    }
  }

  void pauseTimer() async {
    setState(() {
      isRunning = false;
    });
    timer?.cancel();
    await _saveCurrentState(); // Всегда сохраняем состояние при нажатии паузы
  }

  void resetTimer() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.isStandardMode) {
      await prefs.remove(_kStandardTimerStateKey);
      _resetToStandardDefaults();
    } else {
      // It's a named mode. Reset its progress in the savedModes list.
      final index = savedModes.indexWhere((m) => (m['modeName'] ?? m['name']) == modeName);
      if (index != -1) {
        setState(() {
          savedModes[index]['currentExercise'] = 1;
          savedModes[index]['currentRound'] = 1;
          savedModes[index]['remainingTime'] = savedModes[index]['exerciseDuration'];
          savedModes[index]['isBreakTime'] = false;
          savedModes[index]['isRoundBreakTime'] = false;
          savedModes[index]['sessionSeconds'] = 0;
          savedModes[index]['isRunning'] = false;
        });
        await _saveModes();
      }
      if (modeName != 'Таймер' && modeName != 'Стандартный режим') {
        final modeSpecificKey = 'timer_state_$modeName';
        await prefs.remove(modeSpecificKey);
      }
      await prefs.remove(_kLastNamedTimerStateKey);
      // Just reset the progress, keep the mode settings and name
      setState(() {
        isRunning = false;
        currentExercise = 1;
        currentRound = 1;
        remainingTime = exerciseDuration;
        totalTime = exerciseDuration;
        isBreakTime = false;
        isRoundBreakTime = false;
        sessionSeconds = 0;
      });
      timer?.cancel();
    }
  }

  void startBreak() {
    setState(() {
      isBreakTime = true;
      remainingTime = isRoundBreakTime ? roundBreak : exerciseBreak;
      totalTime = isRoundBreakTime ? roundBreak : exerciseBreak;
    });
  }

  void nextExerciseOrRound() {
    if (isRoundBreakTime) {
      setState(() {
        isRoundBreakTime = false;
        isBreakTime = false;
        currentExercise = 1;
        currentRound++;
      });
      startTimer();
    } else {
      setState(() {
        isBreakTime = false;
        if (currentExercise < totalExercises) {
          currentExercise++;
          startTimer();
        } else {
          timer?.cancel();
          resetTimer();
        }
      });
    }
  }

  Future<void> bookmarkMode() async {
    // 1. Define the settings of the mode we are about to save.
    final Map<String, dynamic> newModeSettings = {
      'totalExercises': totalExercises,
      'exerciseDuration': exerciseDuration,
      'exerciseBreak': exerciseBreak,
      'roundDuration': roundDuration,
      'roundBreak': roundBreak,
    };

    // 2. Always create a new mode, even if settings match existing ones
    String baseName = 'Новый режим';
    String modeDisplayName = baseName;
    int counter = 1;
    while (savedModes.any((m) => (m['modeName'] ?? m['name']) == modeDisplayName)) {
      counter++;
      modeDisplayName = '$baseName $counter';
    }

    Map<String, dynamic> modeData = {
      // The settings
      ...newModeSettings,

      // The metadata
      'name': modeDisplayName,
      'modeName': modeDisplayName,
      'icon': Icons.bookmark.codePoint, // A standard icon for templates
      'isIcon': true,

      // Reset progress fields to make it a clean template
      'currentExercise': 1,
      'currentRound': 1,
      'remainingTime': newModeSettings['exerciseDuration'],
      'isBreakTime': false,
      'isRoundBreakTime': false,
      'sessionSeconds': 0,
      'isRunning': false,
    };

    savedModes.add(modeData);
    await _saveModes();

    setState(() {
      isSaved = true;
      // Update the current modeName to the newly created mode's name
      modeName = modeDisplayName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Новый шаблон сохранен: $modeDisplayName'),
        backgroundColor: Colors.green,
      ),
    );

    // After bookmarking, reset the current timer and load the newly created mode
    // to ensure it's completely detached from the previous state.
    resetTimer(); // This will reset the current timer's progress
    loadMode(modeData); // Load the newly created mode as the active one
  }

  void loadMode(Map<String, dynamic> modeData, {bool shouldSaveToPrefs = false}) {
    // Create a clean version of modeData without progress for loading as a template
    final Map<String, dynamic> cleanModeData = {
      ...modeData,
      'currentExercise': 1,
      'currentRound': 1,
      'remainingTime': modeData['exerciseDuration'] ?? 30, // Use its own exerciseDuration
      'isBreakTime': false,
      'isRoundBreakTime': false,
      'sessionSeconds': 0,
      'isRunning': false,
    };
    _applyState(cleanModeData); // Apply the clean state
    if (shouldSaveToPrefs) {
      _saveSelectedModeToPrefs(cleanModeData); // Save the clean state as selected
    }
  }

  Future<void> _saveSelectedModeToPrefs(Map<String, dynamic> modeData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_selected_mode', jsonEncode(modeData));
  }

  Future<void> _loadSelectedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedModeString = prefs.getString('active_mode_for_threescreen');
    if (selectedModeString != null) {
      final modeData = jsonDecode(selectedModeString);
      final newModeName = modeData['modeName'] ?? modeData['name'] ?? 'Таймер';
      setState(() {
        modeName = newModeName;
      });
      final modeSpecificKey = 'timer_state_$newModeName';
      final modeStateString = prefs.getString(modeSpecificKey);

      if (modeStateString != null) {
        // If a saved state for this specific mode exists, load it.
        _applyState(jsonDecode(modeStateString));
      } else {
        // Otherwise, load the mode as a fresh template.
        loadMode(modeData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    double timerFontSize = width * 0.28;
    double cardWidth = width * 0.90;
    double cardHeight = height * 0.24;
    double buttonHeight = height * 0.09;
    double iconSize = width * 0.11;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OneScreen(),
            ),
          );
        } else if (details.primaryVelocity != null &&
            details.primaryVelocity! < 0) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const OneScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, -1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween =
                    Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80), // Отступ для центрирования
                    const Text(
                      'Таймер',
                      style: TextStyle(
                          fontSize: 24.0, fontWeight: FontWeight.bold),
                    ), // Changed from 24.0 to 24
                    if (modeName != 'Таймер')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(modeName, style: const TextStyle(fontSize: 18.0, color: Colors.black54)),
                      ),
                    SizedBox(height: height * 0.01),
                    Spacer(flex: 22),
                    Text(
                      '${(remainingTime ~/ 60).toString().padLeft(2, '0')}:${(remainingTime % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: timerFontSize, fontWeight: FontWeight.bold),
                    ),
                    Spacer(flex: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isRunning ? pauseTimer : startTimer,
                          child: Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,
                            size: iconSize,
                          ),
                        ),
                        if (isRunning) SizedBox(width: width * 0.025),
                        if (isRunning)
                          GestureDetector(
                            onTap: stopTimer,
                            child: Icon(Icons.stop, size: iconSize),
                          ),
                      ],
                    ),
                    SizedBox(height: height * 0.02),
                    if (isSaved)
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Text('Сохранено!', style: TextStyle(color: Colors.blue)),
                      ),
                    Spacer(flex: 2),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _exerciseCard(context, cardWidth, cardHeight, buttonHeight, iconSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseCard(BuildContext context, double cardWidth, double cardHeight, double buttonHeight, double iconSize) {
    return Container(
      padding: const EdgeInsets.all(19),
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow('Упражнения', '$currentExercise/$totalExercises', 26, Colors.black),
          const SizedBox(height: 12),
          _buildRow('Круги', '$currentRound/$roundDuration', 20, Colors.black),
          const SizedBox(height: 12),
          _progressBar(cardWidth),
          const SizedBox(height: 18),
          Row(
            children: [
              _actionButton('Режимы', Icons.settings_input_svideo, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModesScreen(
                      savedModes: savedModes,
                      onDeleteMode: (mode) async {
                        await _loadModesFromRepository();
                      },
                      onModesChanged: () async {
                        await _loadModesFromRepository();
                      },
                    ),
                  ),
                ).then((selectedMode) async {
                  // Always reload saved modes to pick up any changes
                  await _loadModesFromRepository();

                  if (selectedMode != null && selectedMode is Map<String, dynamic>) {
                    // If ModesScreen returned the selected mode, apply it immediately
                    loadMode(selectedMode);
                  } else {
                    // Fallback: reload the selected mode from SharedPreferences
                    await _loadSelectedMode();
                  }

                  await _loadCurrentModeName();
                  setState(() {});
                });
              }, 56, iconSize: 25, labelFontSize: 15),
              SizedBox(width: 8),
              _iconButton(Icons.settings, () async {
                final bool? settingsChanged = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      modeName: modeName,
                    ),
                  ),
                );
                if (settingsChanged == true && mounted) {
                  // 1. Reload the modes list in case the name was changed.
                  await _loadModesFromPrefs();

                  // 2. Reload the current mode name from prefs.
                  await _loadCurrentModeName();

                  // 3. Load the active mode from SharedPreferences, which should have been updated by SettingsScreen.
                  final prefs = await SharedPreferences.getInstance();
                  final activeModeString = prefs.getString('active_mode_for_threescreen');
                  if (activeModeString != null) {
                    final activeMode = jsonDecode(activeModeString) as Map<String, dynamic>;
                    // Apply the new settings but don't start the timer automatically.
                    _applyState(activeMode);
                  } else {
                    // Fallback to global settings if active mode is not set for some reason.
                    await _loadSettings();
                  }
                  // 4. Reset the timer to apply the new settings and discard any old progress.
                  // This ensures the timer starts fresh with the new configuration.
                  resetTimer();
                }
              }, 56, 72, iconSize - 15),
              SizedBox(width: 8),
              _iconButton(Icons.bookmark_border, bookmarkMode, 56, 72, iconSize - 15),
            ],
          ),
        
        ],
      ),
    );
  }

  Widget _buildRow(
    String leftText, String rightText, double fontSize, Color color) {
  return Row(
    children: [
      Text(leftText,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.bold, color: color)),
      const Spacer(),
      Text(rightText,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.blue)),
    ],
  );
}

  Widget _progressBar(double cardWidth) {
    double progressFraction = 0.0;
    if (totalTime > 0) {
      progressFraction = isBreakTime
          ? 1 - (remainingTime / totalTime)
          : (totalTime - remainingTime) / totalTime;
    }

    return Container(
      height: 37,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            alignment:
                isBreakTime ? Alignment.centerRight : Alignment.centerLeft,
            width: max(0.0, (cardWidth - 30)) * progressFraction,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    double height, {
    double iconSize = 24,
    double labelFontSize = 20,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: labelFontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap, double height, double width, double iconSize) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}