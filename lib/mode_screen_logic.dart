import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_barfit/services/mode_repository.dart';
import 'package:new_barfit/models/app_icons.dart';
// Removed unused imports (three_screen and provider) to clean analyzer warnings

class ModeScreenController extends ChangeNotifier {
  final List<Map<String, dynamic>> savedModes;
  final Function(Map<String, dynamic>) onDeleteMode;
  final Function() onModesChanged;

  ModeScreenController({
    required this.savedModes,
    required this.onDeleteMode,
    required this.onModesChanged,
  });

  Future<void> selectMode(BuildContext context, Map<String, dynamic> modeData, int index) async {
    // Set selected index and immediately pop the UI with the selected mode to avoid using
    // the BuildContext across async gaps.
    _selectedIndex = index;
    notifyListeners();

    try {
      // Pop synchronously so the caller can apply the mode immediately.
      Navigator.of(context).pop(modeData);
    } catch (_) {
      // ignore
    }

    // Persist the active mode in background (no await on Navigator pop to avoid context gap).
    // Uses ModeRepository to centralize prefs logic.
    try {
      // Importing here to avoid changing other imports at top of file too much.
      await ModeRepository.setActiveMode(modeData);
    } catch (_) {
      // ignore persistence errors for now
    }
  }

  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;
  set selectedIndex(int? index) {
    _selectedIndex = index;
    notifyListeners();
  }

  int? _editingIndex;
  int? get editingIndex => _editingIndex;
  set editingIndex(int? index) {
    _editingIndex = index;
    notifyListeners();
  }

  final TextEditingController textEditingController = TextEditingController();

  static const List<IconData> availableIcons = AppIcons.modeIcons;

  @override
  void dispose() {
  textEditingController.dispose();
  super.dispose();
  }

  Future<void> loadInitialSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedModeString = prefs.getString('favorite_mode');

    if (selectedModeString != null && savedModes.isNotEmpty) {
      final selectedMode = jsonDecode(selectedModeString);
      final selectedModeName = selectedMode['modeName'] ?? selectedMode['name'];

      if (selectedModeName != null) {
        final index = savedModes.indexWhere((m) {
          final modeName = m['modeName'] ?? m['name'];
          return modeName == selectedModeName;
        });

        if (index != -1) {
          _selectedIndex = index;
          notifyListeners();
        }
      }
    } else {
      // If no favorite, check currentModeName
      final currentModeName = prefs.getString('currentModeName');
      if (currentModeName != null && savedModes.isNotEmpty) {
        final index = savedModes.indexWhere((m) {
          final modeName = m['modeName'] ?? m['name'];
          return modeName == currentModeName;
        });

        if (index != -1) {
          _selectedIndex = index;
          notifyListeners();
        }
      }
    }
  }

  void startEditing(int index, String currentText) {
    _editingIndex = index;
    textEditingController.text = currentText;
    notifyListeners();
  }

  void saveEditing(int index) async {
    if (textEditingController.text.isNotEmpty) {
      final oldName = savedModes[index]['modeName'] ?? savedModes[index]['name'];
      savedModes[index]['name'] = textEditingController.text;
      savedModes[index]['modeName'] = textEditingController.text;
      _editingIndex = null;
      onModesChanged();
      notifyListeners();

      // If this is the current mode, update the currentModeName in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentModeName = prefs.getString('currentModeName');
      if (currentModeName == oldName) {
        await prefs.setString('currentModeName', textEditingController.text);
        // Also update active mode through repository with the new mode data
        await ModeRepository.setActiveMode(savedModes[index]);
      }

      // Update favorite_mode if this mode was favorite
      final currentFavorite = prefs.getString('favorite_mode');
      if (currentFavorite != null) {
        final favoriteMode = jsonDecode(currentFavorite) as Map<String, dynamic>;
        if ((favoriteMode['modeName'] ?? favoriteMode['name']) == oldName) {
          // Update the entire favorite_mode entry with the new mode data
          await prefs.setString('favorite_mode', jsonEncode(savedModes[index]));
        }
      }

      // Update active_mode_for_threescreen if this mode was active
      final activeMode = prefs.getString('active_mode_for_threescreen');
      if (activeMode != null) {
        final activeModeData = jsonDecode(activeMode) as Map<String, dynamic>;
        if ((activeModeData['modeName'] ?? activeModeData['name']) == oldName) {
          // Update the active mode via repository so listeners are notified
          await ModeRepository.setActiveMode(savedModes[index]);
        }
      }

      // Update profile_selected_mode_name if this mode was selected in ProfileScreen
      final currentProfileSelectedModeName = prefs.getString('profile_selected_mode_name');
      if (currentProfileSelectedModeName == oldName) {
        await prefs.setString('profile_selected_mode_name', textEditingController.text);
      }
    } else {
      _editingIndex = null; // Just cancel editing
      notifyListeners();
    }
  }

  Future<void> selectIcon(BuildContext context, int index) async {
    final IconData? selected = await showDialog<IconData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите иконку'),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableIcons.map((icon) {
              return IconButton(
                icon: Icon(icon, size: 32),
                onPressed: () => Navigator.pop(context, icon),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      savedModes[index]['icon'] = selected.codePoint;
      onModesChanged();
      notifyListeners();
    }
  }

  Future<void> addNewMode(String name) async {
    // Check if a mode with this name already exists
    if (savedModes.any((m) => (m['modeName'] ?? m['name']) == name)) {
      // Mode with this name already exists, do not add duplicate
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final exerciseCount = prefs.getInt('exerciseCount') ?? 5;
    final exerciseDuration = prefs.getInt('exerciseDuration') ?? 30;
    final exerciseBreak = prefs.getInt('exerciseBreak') ?? 10;
    final roundCount = prefs.getInt('roundCount') ?? 5;
    final roundBreak = prefs.getInt('roundBreak') ?? 30;

    final int totalWorkTimeSeconds = exerciseDuration * exerciseCount * roundCount;

    int iconCodePoint = availableIcons[0].codePoint;
    Map<String, dynamic> newMode = {
      'name': name,
      'modeName': name,
      'icon': iconCodePoint,
      'totalExercises': exerciseCount,
      'exerciseDuration': exerciseDuration,
      'exerciseBreak': exerciseBreak,
      'roundDuration': roundCount,
      'roundBreak': roundBreak,
      'totalWorkTime': totalWorkTimeSeconds,
      'currentExercise': 1,
      'currentRound': 1,
      'remainingTime': exerciseDuration,
      'isBreakTime': false,
      'isRoundBreakTime': false,
      'sessionSeconds': 0,
      'isFavorite': false,
      'isIcon': true,
    };
    savedModes.add(newMode);
    onModesChanged();
    notifyListeners();
  }

  void showAddModeDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 120,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Создать новый режим',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Название режима',
                hintText: 'например, "Утренняя зарядка"',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Добавить режим', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    addNewMode(controller.text);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                child: const Text('Отмена', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showDeleteConfirmationDialog(BuildContext context, Map<String, dynamic> mode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 120,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, color: Colors.redAccent, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Вы точно желаете удалить режим "${mode['name'] ?? '...'}", из сохраненных режимов?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 64,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    savedModes.remove(mode);
                    await ModeRepository.saveSavedModes(savedModes);
                    // После удаления сразу обновляем SharedPreferences и UI
                    final prefs = await SharedPreferences.getInstance();
                    // Если удалённый режим был favorite_mode — сбросить
                    final currentFavorite = prefs.getString('favorite_mode');
                    if (currentFavorite != null) {
                      final favoriteMode = jsonDecode(currentFavorite) as Map<String, dynamic>;
                      if ((favoriteMode['modeName'] ?? favoriteMode['name']) == (mode['modeName'] ?? mode['name'])) {
                        await prefs.remove('favorite_mode');
                      }
                    }
                    // Если удалённый режим был активным — сбросить
                    final activeMode = prefs.getString('active_mode_for_threescreen');
                    if (activeMode != null) {
                      final activeModeData = jsonDecode(activeMode) as Map<String, dynamic>;
                      if ((activeModeData['modeName'] ?? activeModeData['name']) == (mode['modeName'] ?? mode['name'])) {
                        await ModeRepository.clearActiveMode();
                      }
                    }
                    onDeleteMode(mode);
                    notifyListeners();
                    // Обновить UI
                    onModesChanged();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [ Icon(Icons.check_circle_outline, size: 26,),
                    SizedBox(width: 5,),
                      Text('Да, удалить', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [ Icon(Icons.cancel_outlined, size: 26,),
                    SizedBox(width: 5,),
                      Text('Нет, не удалять', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes мин $seconds сек';
  }

  void toggleFavorite(BuildContext context, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final modeToToggle = savedModes[index];
    final modeToToggleName = modeToToggle['modeName'] ?? modeToToggle['name'];
    
    final currentSelectedModeString = prefs.getString('favorite_mode');
    String? currentSelectedName;
    if (currentSelectedModeString != null) {
      final currentSelectedMode = jsonDecode(currentSelectedModeString);
      currentSelectedName = currentSelectedMode['modeName'] ?? currentSelectedMode['name'];
    }

    // If the tapped mode is the current favorite, deselect it. Otherwise, select it.
    if (currentSelectedName == modeToToggleName) {
      // Deselect favorite
      await prefs.remove('favorite_mode');
      // If favorite was also used as the currentModeName, remove that link
      final curName = prefs.getString('currentModeName');
      if (curName == modeToToggleName) {
        await prefs.remove('currentModeName');
      }
      // Clear active mode through repository so UI listeners update immediately
      await ModeRepository.clearActiveMode();
    } else {
      // Select favorite
      await prefs.setString('favorite_mode', jsonEncode(modeToToggle));
      await prefs.remove('last_named_timer_state');
      // Also set this mode as the currentModeName so other screens reflect the favorite
      final modeNameForKey = (modeToToggle['modeName'] ?? modeToToggle['name'])?.toString() ?? '';
      if (modeNameForKey.isNotEmpty) {
        await prefs.setString('currentModeName', modeNameForKey);
      }
      // Set active mode through repository so listeners receive the update immediately
      await ModeRepository.setActiveMode(modeToToggle);
    }

    // Update all modes' isFavorite status to reflect the new selection for the star icon
    final newSelectedModeString = prefs.getString('favorite_mode');
    String? newSelectedName;
    if (newSelectedModeString != null) {
        final newSelectedMode = jsonDecode(newSelectedModeString);
        newSelectedName = newSelectedMode['modeName'] ?? newSelectedMode['name'];
    }

    for (var mode in savedModes) {
      final modeName = mode['modeName'] ?? mode['name'];
      if (modeName == newSelectedName) {
        mode['isFavorite'] = true;
      } else {
        mode['isFavorite'] = false;
      }
    }

    onModesChanged();
    notifyListeners();
  }
}
