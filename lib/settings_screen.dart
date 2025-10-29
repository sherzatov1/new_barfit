import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_barfit/services/mode_repository.dart';
import 'package:new_barfit/mode_screen_logic.dart';
import 'package:new_barfit/models/app_icons.dart';

class SettingsScreen extends StatefulWidget {
  final String modeName;
  final int? iconCodePoint;

  const SettingsScreen({super.key, this.modeName = 'Режим победителя', this.iconCodePoint});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController exerciseCountController = TextEditingController();
  final TextEditingController roundDurationController = TextEditingController();
  late TextEditingController _modeNameController; // New: Controller for mode name
  IconData _selectedIcon = Icons.fitness_center;
  final List<IconData> _availableIcons = AppIcons.modeIcons;

  int roundMinutes = 8;
  int roundBreakMinutes = 2;
  int roundBreakSeconds = 0;
  int exerciseMinutes = 0;
  int exerciseSeconds = 30;
  int exerciseBreakMinutes = 0;
  int exerciseBreakSeconds = 10;
  String selectedMelody = 'sounds/002.mp3';
  final List<String> melodies = [
    'sounds/002.mp3',
    'sounds/006.mp3',
    'sounds/007.mp3',
    'sounds/008.mp3',
    'sounds/009.mp3',
    'sounds/010.mp3',
    'sounds/011.mp3',
    'sounds/012.mp3',
    'sounds/013.mp3',
    'sounds/014.mp3',
    'sounds/015.mp3'
  ];
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingMelody;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _modeNameController = TextEditingController(text: widget.modeName);
    if (widget.iconCodePoint != null) {
      _selectedIcon = AppIcons.fromCodePoint(widget.iconCodePoint!);
    }
    exerciseCountController.addListener(() => setState(() {}));
    roundDurationController.addListener(() => setState(() {}));
    _loadSettings();
  }

  @override
  void dispose() {
    exerciseCountController.dispose();
    roundDurationController.dispose();
    _modeNameController.dispose(); // Dispose modeNameController
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playMelody(String path, StateSetter setModalState) async {
    try {
      if (_isPlaying && _currentlyPlayingMelody == path) {
        // если нажали на ту же мелодию → стоп
        await _audioPlayer.stop();
        setModalState(() {
          _isPlaying = false;
          _currentlyPlayingMelody = null;
        });
      } else {
        // останавливаем предыдущую и проигрываем новую
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(path));
        
        setState(() {
          selectedMelody = path;
        });
        setModalState(() {
          _isPlaying = true;
          _currentlyPlayingMelody = path;
        });
      }
    } catch (e) {
      debugPrint("Ошибка воспроизведения: $e");
    }
  }

  void _stopMelody() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentlyPlayingMelody = null;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // First, try to load from savedModes for the specific mode
    final savedModes = await ModeRepository.loadSavedModes();

    int modeIndex = savedModes.indexWhere((m) => (m['modeName'] ?? m['name']) == widget.modeName);

    if (modeIndex != -1) {
      final mode = savedModes[modeIndex];
      setState(() {
        exerciseCountController.text = (mode['totalExercises'] ?? 5).toString();
        roundDurationController.text = (mode['roundDuration'] ?? 5).toString();
        int exerciseDuration = mode['exerciseDuration'] ?? 30;
        exerciseMinutes = exerciseDuration ~/ 60;
        exerciseSeconds = exerciseDuration % 60;
        int exerciseBreak = mode['exerciseBreak'] ?? 10;
        exerciseBreakMinutes = exerciseBreak ~/ 60;
        exerciseBreakSeconds = exerciseBreak % 60;
        int roundBreak = mode['roundBreak'] ?? 30;
        roundBreakMinutes = roundBreak ~/ 60;
        roundBreakSeconds = roundBreak % 60;
        selectedMelody = prefs.getString('selectedMelody') ?? 'sounds/002.mp3'; // Melody is global
        final iconValue = mode['icon'];
        if (iconValue is int) {
          _selectedIcon = AppIcons.fromCodePoint(iconValue);
        }
      });
    } else {
      // Fallback to global settings if mode not found
      setState(() {
        exerciseCountController.text = (prefs.getInt('exerciseCount') ?? 5).toString();
        roundDurationController.text = (prefs.getInt('roundDuration') ?? 5).toString();
        int exerciseDuration = prefs.getInt('exerciseDuration') ?? 30;
        exerciseMinutes = exerciseDuration ~/ 60;
        exerciseSeconds = exerciseDuration % 60;
        int exerciseBreak = prefs.getInt('exerciseBreak') ?? 10;
        exerciseBreakMinutes = exerciseBreak ~/ 60;
        exerciseBreakSeconds = exerciseBreak % 60;
        int roundBreak = prefs.getInt('roundBreak') ?? 30;
        roundBreakMinutes = roundBreak ~/ 60;
        roundBreakSeconds = roundBreak % 60;
        selectedMelody = prefs.getString('selectedMelody') ?? 'sounds/002.mp3';
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String oldModeName = widget.modeName;
    int exerciseBreakTotalSeconds = exerciseBreakMinutes * 60 + exerciseBreakSeconds;
    int roundBreakTotalSeconds = roundBreakMinutes * 60 + roundBreakSeconds;

    // Save global melody setting
    await prefs.setString('selectedMelody', selectedMelody);

    // Load existing modes through the repository to ensure we have the deduplicated list
    List<Map<String, dynamic>> savedModes = await ModeRepository.loadSavedModes();

    final String currentModeName = _modeNameController.text.trim();
    int modeIndex = savedModes.indexWhere((m) => ((m['modeName'] ?? m['name'])?.toString().trim()) == currentModeName);

    // Check if a mode with the new name already exists, but it's not the one we're editing.
    final newName = currentModeName;
    int existingModeWithNewNameIndex = savedModes.indexWhere((m) => ((m['modeName'] ?? m['name'])?.toString().trim()) == newName);

    if (existingModeWithNewNameIndex != -1 && existingModeWithNewNameIndex != modeIndex) {
      // A different mode with this new name already exists. Remove it to replace with the updated one.
      savedModes.removeAt(existingModeWithNewNameIndex);
    }

    // Create updated mode data
    final String newModeName = _modeNameController.text.trim();
    Map<String, dynamic> modeData = {
      'name': newModeName,
      'modeName': newModeName,
      'icon': _selectedIcon.codePoint,
      'totalExercises': int.tryParse(exerciseCountController.text) ?? 5,
      'exerciseDuration': exerciseMinutes * 60 + exerciseSeconds,
      'exerciseBreak': exerciseBreakTotalSeconds,
      'roundDuration': int.tryParse(roundDurationController.text) ?? 5,
      'roundBreak': roundBreakTotalSeconds,
      // Reset progress fields
      'currentExercise': 1,
      'currentRound': 1,
      'remainingTime': exerciseMinutes * 60 + exerciseSeconds,
      'isBreakTime': false,
      'isRoundBreakTime': false,
      'sessionSeconds': 0,
      'isRunning': false,
    };

    // Если режим существует, обновляем его на месте
    if (modeIndex != -1) {
      savedModes[modeIndex] = modeData;
    } else {
      // Если режим новый, добавляем
      savedModes.add(modeData);
    }
    await ModeRepository.saveSavedModes(savedModes);

    // Always set the active mode to the just-saved settings
    await ModeRepository.setActiveMode(modeData);
    await prefs.setString('currentModeName', newModeName);

    // Update favorite_mode if this mode was favorite
    final currentFavorite = prefs.getString('favorite_mode');
    if (currentFavorite != null) {
      final favoriteMode = jsonDecode(currentFavorite) as Map<String, dynamic>;
      if (favoriteMode['modeName'] == oldModeName || favoriteMode['name'] == oldModeName) {
        favoriteMode['modeName'] = newModeName;
        favoriteMode['name'] = newModeName;
        favoriteMode['totalExercises'] = modeData['totalExercises'];
        favoriteMode['exerciseDuration'] = modeData['exerciseDuration'];
        favoriteMode['exerciseBreak'] = modeData['exerciseBreak'];
        favoriteMode['roundDuration'] = modeData['roundDuration'];
        favoriteMode['roundBreak'] = modeData['roundBreak'];
        await prefs.setString('favorite_mode', jsonEncode(favoriteMode));
      }
    }

    // Define favoriteMode
    Map<String, dynamic> favoriteMode = {};

    // Check if the mode already exists
    final existingMode = prefs.getString('favorite_mode');
    if (existingMode != null) {
      final existingModeData = jsonDecode(existingMode) as Map<String, dynamic>;
      if (existingModeData['modeName'] == _modeNameController.text) {
        // Update existing mode
        favoriteMode = existingModeData;
      }
    }

    // Update favoriteMode properties
    favoriteMode['modeName'] = _modeNameController.text;
    favoriteMode['name'] = _modeNameController.text;
    await prefs.setString('favorite_mode', jsonEncode(favoriteMode));

    // Update active_mode_for_threescreen if this mode was active
    final activeMode = prefs.getString('active_mode_for_threescreen');
    if (activeMode != null) {
      final activeModeData = jsonDecode(activeMode) as Map<String, dynamic>;
      if (activeModeData['modeName'] == widget.modeName || activeModeData['name'] == widget.modeName) {
        activeModeData['modeName'] = _modeNameController.text;
        activeModeData['name'] = _modeNameController.text;
        await ModeRepository.setActiveMode(activeModeData);
      }
    }

    Navigator.of(context).pop();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes мин $seconds сек';
  }

  String _calculateTotalWorkTime() {
    final int exerciseCount = int.tryParse(exerciseCountController.text) ?? 0;
    final int exerciseDuration = exerciseMinutes * 60 + exerciseSeconds;

    final totalSeconds = exerciseDuration * exerciseCount;
    return _formatDuration(totalSeconds);
  }

  // _calculateTotalRoundBreakTime removed (unused)

  void _showCustomDurationPicker(BuildContext context, String title,
      int initialMinutes, int initialSeconds, Function(int, int) onConfirm, {bool isExerciseDuration = false, bool isBreak = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes the sheet scrollable
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        int selectedMinutes = initialMinutes;
        int selectedSeconds = initialSeconds;
        // Контроллеры для начальных значений
        final FixedExtentScrollController minutesController =
            FixedExtentScrollController(initialItem: initialMinutes);
        final FixedExtentScrollController secondsController =
            FixedExtentScrollController(initialItem: initialSeconds);

        return SingleChildScrollView( // Allows content to scroll
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Adjust for keyboard
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Takes minimum required space
              children: [
                // Верхняя часть диалогового окна
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (isExerciseDuration)
                          Icon(
                            isBreak ? Icons.pause_circle_outline : Icons.watch_later_outlined,
                            color: Colors.black,
                            size: isBreak ? 45 : 48,
                          ),
                        if (isExerciseDuration) const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (isExerciseDuration)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: Text(
                            isBreak
                                ? 'Выберите длительность перерыва'
                                : 'Выберите длительность каждого упражнения',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Заголовок для минут
                        const Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Text(
                            'МИН',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Рулетка для минут
                        Expanded(
                          child: Container(
                            height: 180,
                            child: ListWheelScrollView(
                              controller: minutesController,
                              itemExtent: 80,
                              diameterRatio: 1.2,
                              perspective: 0.005,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                selectedMinutes = index;
                              },
                              children: List<Widget>.generate(4, (index) {
                                return Center(
                                  child: Text(
                                    '$index',
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Рулетка для секунд
                        Expanded(
                          child: Container(
                            height: 180,
                            child: ListWheelScrollView(
                              controller: secondsController,
                              itemExtent: 80,
                              diameterRatio: 1.2,
                              perspective: 0.005,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                selectedSeconds = index;
                              },
                              children: List<Widget>.generate(60, (index) {
                                return Center(
                                  child: Text(
                                    '$index',
                                    style: const TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        // Заголовок для секунд
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Text(
                            'СЕК',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Spacer
                // Нижняя часть с кнопками
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          onConfirm(selectedMinutes, selectedSeconds);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text(
                          'Отменить',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditBottomSheet(BuildContext context, String title,
      List<TextEditingController> controllers, List<String> labels, {bool isExerciseSettings = false, String? spritePath}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  minHeight: 0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (spritePath != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.asset(spritePath, width: 48, height: 48),
                            ),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Контейнер для ввода количества упражнений или кругов
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (spritePath != null) Image.asset(spritePath, width: 24, height: 24) else const Icon(Icons.fitness_center, color: Colors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: controllers[0],
                                decoration: InputDecoration(
                                  labelText: labels[0],
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isExerciseSettings) ...[
                        const SizedBox(height: 20),
                        // Длительность
                        GestureDetector(
                          onTap: () => _showCustomDurationPicker(
                            context,
                            'Выбрать время',
                            exerciseMinutes,
                            exerciseSeconds,
                            (minutes, seconds) {
                              setState(() {
                                exerciseMinutes = minutes;
                                exerciseSeconds = seconds;
                              });
                              setModalState(() {});
                            },
                            isExerciseDuration: true,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.timer, color: Colors.blue),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Длительность',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$exerciseMinutes мин $exerciseSeconds сек',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Длительность перерыва
                      GestureDetector(
                        onTap: () {
                          if (isExerciseSettings) {
                            _showCustomDurationPicker(
                              context,
                              'Выбрать время',
                              exerciseBreakMinutes,
                              exerciseBreakSeconds,
                              (minutes, seconds) {
                                setState(() {
                                  exerciseBreakMinutes = minutes;
                                  exerciseBreakSeconds = seconds;
                                });
                                setModalState(() {});
                              },
                              isExerciseDuration: true,
                              isBreak: true,
                            );
                          } else {
                            _showCustomDurationPicker(
                              context,
                              'Выбрать время',
                              roundBreakMinutes,
                              roundBreakSeconds,
                              (minutes, seconds) {
                                setState(() {
                                  roundBreakMinutes = minutes;
                                  roundBreakSeconds = seconds;
                                });
                                setModalState(() {});
                              },
                              isExerciseDuration: true,
                              isBreak: true,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.pause_circle_filled, color: Colors.blue),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Перерыв',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                isExerciseSettings
                                    ? '$exerciseBreakMinutes мин $exerciseBreakSeconds сек'
                                    : '$roundBreakMinutes мин $roundBreakSeconds сек',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Кнопки по вертикали, обе синие
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {});
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Сохранить', style: TextStyle(color: Colors.white),),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              child: const Text('Отменить', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog() {
    final TextEditingController controller =
        TextEditingController(text: _modeNameController.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Изменить название режима'),
          content: TextField(
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _modeNameController.text = controller.text;
                });
                // Сохраняем изменённое имя в SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('currentModeName', _modeNameController.text);

                // Update the mode name in savedModes list
                final savedModesString = prefs.getStringList('savedModes');
                if (savedModesString != null) {
                  List<Map<String, dynamic>> savedModes = savedModesString
                      .map((m) => jsonDecode(m) as Map<String, dynamic>)
                      .toList();

                  int modeIndex = savedModes.indexWhere((m) => (m['modeName'] ?? m['name']) == widget.modeName);

                  if (modeIndex != -1) {
                    savedModes[modeIndex]['name'] = _modeNameController.text;
                    savedModes[modeIndex]['modeName'] = _modeNameController.text;

                    await ModeRepository.saveSavedModes(savedModes);
                  }
                }

                // Update favorite_mode if this mode was favorite
                final currentFavorite = prefs.getString('favorite_mode');
                if (currentFavorite != null) {
                  final favoriteMode = jsonDecode(currentFavorite) as Map<String, dynamic>;
                  if (favoriteMode['modeName'] == widget.modeName || favoriteMode['name'] == widget.modeName) {
                    favoriteMode['modeName'] = _modeNameController.text;
                    favoriteMode['name'] = _modeNameController.text;
                    await prefs.setString('favorite_mode', jsonEncode(favoriteMode));
                  }
                }

                // Update active_mode_for_threescreen if this mode was active
                final activeMode = prefs.getString('active_mode_for_threescreen');
                if (activeMode != null) {
                  final activeModeData = jsonDecode(activeMode) as Map<String, dynamic>;
                  if (activeModeData['modeName'] == widget.modeName || activeModeData['name'] == widget.modeName) {
                    activeModeData['modeName'] = _modeNameController.text;
                    activeModeData['name'] = _modeNameController.text;
                    await ModeRepository.setActiveMode(activeModeData);
                  }
                }

                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _showIconPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите иконку'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableIcons.map((icon) {
              return IconButton(
                icon: Icon(icon, size: 32),
                onPressed: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

 
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth > 500 ? 440 : screenWidth * 0.97;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16), // Добавили отступы
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Все ваши карточки идут тут, теперь с отступами слева и справа
                  Container(
                    width: cardWidth,
                    constraints: const BoxConstraints(minHeight: 80), // минимальная высота
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24), // увеличили padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20), // чуть больше скругление
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showIconPickerDialog,
                          child: Icon(_selectedIcon, size: 32, color: Colors.black),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showEditNameDialog,
                            child: Text(_modeNameController.text,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.star, color: Colors.blue, size: 30),
                          onPressed: _saveSettings,
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark, color: Colors.blue, size: 30),
                          onPressed: _saveSettings,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Круги
                  Container(
                    width: cardWidth,
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/calipso.png', width: 56, height: 56),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Круги',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            buildEditCard(
                              Icons.timer,
                              'Длительность',
                              _calculateTotalWorkTime(),
                              () => _showEditBottomSheet(
                                context,
                                'Круги',
                                [roundDurationController],
                                ['Введите количество кругов'],
                                spritePath: 'assets/calipso.png',
                              ),
                            ),
                            const SizedBox(height: 6),
                            buildEditCard(
                              Icons.pause_circle,
                              'Перерыв',
                              '$roundBreakMinutes мин $roundBreakSeconds сек',
                              () => _showEditBottomSheet(
                                context,
                                'Круги',
                                [roundDurationController],
                                ['Введите количество кругов'],
                                spritePath: 'assets/calipso.png',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Упражнения
                  Container(
                    width: cardWidth,
                    constraints: const BoxConstraints(minHeight: 110),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/group.png', width: 56, height: 56),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Упражнения',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            buildEditCard(
                              Icons.timer,
                              'Длительность',
                              '$exerciseMinutes мин $exerciseSeconds сек',
                              () => _showEditBottomSheet(
                                context,
                                'Упражнения',
                                [exerciseCountController],
                                ['Введите количество упражнений'],
                                isExerciseSettings: true,
                                spritePath: 'assets/group.png',
                              ),
                            ),
                            const SizedBox(height: 6),
                            buildEditCard(
                              Icons.pause,
                              'Перерыв',
                              '$exerciseBreakMinutes мин $exerciseBreakSeconds сек',
                              () => _showEditBottomSheet(
                                context,
                                'Упражнения',
                                [exerciseCountController],
                                ['Введите количество упражнений'],
                                isExerciseSettings: true,
                                spritePath: 'assets/group.png',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Музыка
                  GestureDetector(
                    onTap: () => _showBottomSheet(context, 'Мелодия'),
                    child: Container(
                      width: cardWidth,
                      constraints: const BoxConstraints(minHeight: 80),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.music_note, color: Colors.blue, size: 28),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Мелодия',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                          ),
                         
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await _saveSettings();
                              if (!mounted) return;
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Отменить', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the sheet to be larger
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            _audioPlayer.onPlayerStateChanged.listen((state) {
              if (state == PlayerState.completed) {
                setModalState(() {
                  _isPlaying = false;
                  _currentlyPlayingMelody = null;
                });
              }
            });

            // Makes the sheet responsive and avoids overflow
            return Container(
              height: 450,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start, // Center content horizontally
                      children: [
                        Center(
                          child: Container(
                            width: 120, // Increased width
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.music_note, color: Colors.black, size: 48),
                            SizedBox(width: 8),
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: melodies.length,
                      itemBuilder: (context, index) {
                        final melody = melodies[index];
                        final isSelected = selectedMelody == melody;
                        final isPlaying =
                            _currentlyPlayingMelody == melody && _isPlaying;

                        return GestureDetector(
                          onTap: () {
                            _playMelody(melody, setModalState);
                          },
                          child: Container(
                            height: 56,
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -5),
                                  child: IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.blue,
                                    ),
                                    onPressed: () {
                                      _playMelody(melody, setModalState);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Мелодия ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  const Icon(Icons.check,
                                        color: Colors.white)
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _stopMelody();
    });
  }

  Widget buildEditCard(IconData icon, String title, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
