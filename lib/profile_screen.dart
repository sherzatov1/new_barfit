import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_barfit/models/app_icons.dart';
import 'one_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_barfit/services/mode_repository.dart';

// _kLastNamedTimerStateKey is declared in three_screen.dart; removed duplicate here.

void main() {
  runApp(MaterialApp(home: OneScreen()));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final Color customBlue = const Color(0xFF2785FF);
  final Color customBlueLight = const Color(0xFFA0C7FF);

  String? _userName, _userLastName;
  String? _selectedIconKey;
  bool _isLoading = true;
  int _secondsSpent = 0, _goalMinutes = 30;
  List<int> _dailyTimes = List.generate(7, (_) => 0);
  List<int> _displayedDailyTimes = List.generate(7, (_) => 0);
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _allDefaultModes = [];
  int? _selectedModeIndex;

  // Define _availableIconsProfile
  final Map<String, IconData> _availableIconsProfile = {
    'directions_run': Icons.directions_run,
    'fitness_center': Icons.fitness_center,
    'sports_kabaddi': Icons.sports_kabaddi,
    'sports_handball': Icons.sports_handball,
    'sports_basketball': Icons.sports_basketball,
    'sports_football': Icons.sports_football,
    'sports_tennis': Icons.sports_tennis,
    'sports_volleyball': Icons.sports_volleyball,
    'sports_baseball': Icons.sports_baseball,
    'sports_cricket': Icons.sports_cricket,
    'sports_golf': Icons.sports_golf,
    'sports_hockey': Icons.sports_hockey,
    'sports_motorsports': Icons.sports_motorsports,
    'sports_soccer': Icons.sports_soccer,
  };
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProfileData();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfileData();
    }
  }

  Future<void> _saveModes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'savedModes', _allDefaultModes.map((e) => jsonEncode(e)).toList());
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime now = DateTime.now();
    final int today = now.weekday;
    int lastSavedDay = prefs.getInt('currentDay') ?? today;

    _userName = prefs.getString('userName') ?? 'Guest';
    _userLastName = prefs.getString('userLastName') ?? '';
    _secondsSpent = prefs.getInt('sharedTimer') ?? 0;
    _goalMinutes = prefs.getInt('goalMinutes') ?? 30;
    _dailyTimes = (prefs.getStringList('dailyTimes')?.map(int.parse).toList() ?? List.generate(7, (_) => 0));
    _selectedDate = prefs.getString('selectedDate') != null ? DateTime.parse(prefs.getString('selectedDate')!) : now;
    _selectedIconKey = prefs.getString('selectedIconKey');

    if (lastSavedDay != today) {
      if (today == 1 && lastSavedDay != 1) {
        _saveWeeklyStats(now.subtract(const Duration(days: 1)));
        _resetWeeklyStats();
      }
      prefs.setInt('currentDay', today);
      _secondsSpent = 0;
      // prefs.setInt('sharedTimer', 0); // Removed to prevent conflict with one_screen
    }
    
    _dailyTimes[today - 1] = _secondsSpent;
    _loadWeeklyStatsForDate(_selectedDate);

    // Setup default modes
    _allDefaultModes = [];

    final savedModesString = prefs.getStringList('savedModes');
    if (savedModesString != null && savedModesString.isNotEmpty) {
      try {
        final allModes = savedModesString
            .map((m) => jsonDecode(m) as Map<String, dynamic>)
            .toList();
        
        // Convert old index-based icons to codePoints
        for (var mode in allModes) {
          if (mode['icon'] is int) {
            int iconValue = mode['icon'];
            // Check if it's an old index (small number)
            if (iconValue >= 0 && iconValue < AppIcons.modeIcons.length) {
              mode['icon'] = AppIcons.modeIcons[iconValue].codePoint;
            }
          }
        }

        _allDefaultModes.addAll(allModes);
      } catch (e) {
        print('Error decoding saved modes: $e');
      }
    }
    
    if (_allDefaultModes.isEmpty) {
      Map<String, dynamic> defaultMode = {
        'name': 'Стандартный режим',
        'modeName': 'Стандартный режим',
        'icon': AppIcons.modeIcons[0].codePoint, // Use codePoint for default
        'totalExercises': 5,
        'exerciseDuration': 30,
        'exerciseBreak': 10,
        'roundDuration': 5,
        'roundBreak': 30,
        'isFavorite': false,
        'isIcon': true,
        'currentExercise': 1,
        'currentRound': 1,
        'remainingTime': 30,
        'isBreakTime': false,
        'isRoundBreakTime': false,
        'sessionSeconds': 0,
      };
      _allDefaultModes.add(defaultMode);
      await _saveModes();
    }

    final selectedModeString = prefs.getString('profile_screen_selected_mode');
    if (selectedModeString != null) {
      try {
        final selectedModeData = jsonDecode(selectedModeString) as Map<String, dynamic>;
        _selectedModeIndex = _allDefaultModes.indexWhere((m) => 
          (m['modeName'] ?? m['name']) == (selectedModeData['modeName'] ?? selectedModeData['name'])
        );
        if (_selectedModeIndex == -1) {
          prefs.remove('profile_screen_selected_mode');
        }
      } catch (e) {
        print('Error decoding selected mode: $e');
        prefs.remove('profile_screen_selected_mode');
      }
    } else {
      _selectedModeIndex = null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName!);
    await prefs.setString('userLastName', _userLastName!);
    await prefs.setInt('goalMinutes', _goalMinutes);
    await prefs.setStringList('dailyTimes', _dailyTimes.map((e) => e.toString()).toList());
    await prefs.setInt('currentDay', DateTime.now().weekday);
    await prefs.setString('selectedDate', _selectedDate.toIso8601String());
    if (_selectedIconKey != null) {
      await prefs.setString('selectedIconKey', _selectedIconKey!);
    }
  }

  Future<void> _saveWeeklyStats(DateTime dateForWeek) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime startOfWeek = dateForWeek.subtract(Duration(days: dateForWeek.weekday - 1));
    final String weekKey = 'week_${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';
    await prefs.setStringList(weekKey, _dailyTimes.map((e) => e.toString()).toList());
  }

  void _resetWeeklyStats() {
    setState(() {
      _dailyTimes = List.generate(7, (_) => 0);
      _displayedDailyTimes = List.generate(7, (_) => 0);
    });
  }

  Future<void> _loadWeeklyStatsForDate(DateTime date) async {
    final DateTime now = DateTime.now();
    if (_isSameWeek(date, now)) {
      setState(() {
        _displayedDailyTimes = List.from(_dailyTimes);
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final String weekKey = 'week_${startOfWeek.year}_${startOfWeek.month}_${startOfWeek.day}';
      final List<String>? savedTimes = prefs.getStringList(weekKey);
      setState(() {
        if (savedTimes != null) {
          _displayedDailyTimes = savedTimes.map(int.parse).toList();
        } else {
          _displayedDailyTimes = List.generate(7, (_) => 0);
        }
      });
    }
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final DateTime aStartOfWeek = a.subtract(Duration(days: a.weekday - 1));
    final DateTime bStartOfWeek = b.subtract(Duration(days: b.weekday - 1));
    return aStartOfWeek.year == bStartOfWeek.year &&
           aStartOfWeek.month == bStartOfWeek.month &&
           aStartOfWeek.day == bStartOfWeek.day;
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Выберите иконку', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _availableIconsProfile.entries.map((entry) {
                    return GestureDetector(
                      onTap: () async { // Added async
                        setState(() {
                          _selectedIconKey = entry.key;
                        });
                        await _saveProfileData(); // Added await
                        Navigator.of(context).pop();
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: _selectedIconKey == entry.key ? customBlueLight : Colors.grey.shade200,
                        child: Icon(entry.value, size: 35, color: _selectedIconKey == entry.key ? customBlue : Colors.black54),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        _loadProfileData(); // Call _loadProfileData after modal is dismissed
      }
    });
  }

  void _editUserName() async {
    final newName = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final controllerFirstName = TextEditingController(text: _userName);
        final controllerLastName = TextEditingController(text: _userLastName);
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Изменить имя и фамилию', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: controllerFirstName, decoration: const InputDecoration(labelText: 'Имя пользователя')),
                TextField(controller: controllerLastName, decoration: const InputDecoration(labelText: 'Фамилия пользователя')),
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop({'firstName': controllerFirstName.text, 'lastName': controllerLastName.text});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: customBlue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Сохранить', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w200, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: customBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Отмена', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w200, color: Colors.white)),
                      ),
                    ),
                    Container(child: const SizedBox(height: 30))
                  ],
                )
              ],
            ),
          ),
        );
      },
    );

    if (newName != null) {
      setState(() {
        _userName = newName['firstName'];
        _userLastName = newName['lastName'];
      });
      _saveProfileData();
    }
  }

  void _setGoalTime() async {
    int selectedMinutes = _goalMinutes;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 120,
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
                    const Icon(Icons.timelapse, size: 40, ),
                    const Text('Изменить цель', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Сколько минут в день вы готовы уделить тренировке?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 118,
                  child: CupertinoPicker(
                    itemExtent: 32.0,
                    scrollController: FixedExtentScrollController(initialItem: selectedMinutes),
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        selectedMinutes = index;
                      });
                    },
                    children: List<Widget>.generate(181, (int index) {
                      return Center(child: Text('$index мин'));
                    }),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _goalMinutes = selectedMinutes;
                      });
                      _saveProfileData();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customBlue,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Сохранить', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customBlue,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Отменить', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30)
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadWeeklyStatsForDate(picked);
      _saveProfileData();
    }
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade300,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 15),
              _buildStatisticsContainer(),
              const SizedBox(height: 10),
              _buildDefaultModes(),
            ],
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onTap: _showIconPicker,
                child: CircleAvatar(
                  radius: 50.5,
                  backgroundColor: customBlue,
                  child: CircleAvatar(
                    radius: 45.5,
                    backgroundColor: Colors.white,
                    child: Icon(
                        _selectedIconKey != null ? _availableIconsProfile[_selectedIconKey]! : Icons.account_circle_outlined,
                        size: 52,
                        color: Colors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _editUserName,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _userName ?? 'Guest',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (_userLastName != null && _userLastName!.isNotEmpty)
                      Text(
                        _userLastName!,
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          height: 104,
          width: MediaQuery.of(context).size.width * 0.95,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      Icon(Icons.timelapse, size: 48, color: customBlue),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 115,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Моя цель',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text('$_goalMinutes минут', style:  TextStyle(fontSize: 16, color: customBlue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: _setGoalTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      minimumSize: const Size(80, 55),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                    ),
                    child: Text(
                      "Задать",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: customBlue,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsContainer() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        width: MediaQuery.of(context).size.width * 0.95,
        height: 270,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatistics(),
            Spacer(),
            _buildDateRange(),
            const SizedBox(height: 8),
            _buildDailyStats(),
            _buildDayLabels(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text('Статистика', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
           Spacer(),
          Text(_formatTime(_secondsSpent), style: TextStyle(color: customBlue, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDateRange() {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final String formattedStartDate = "${startOfWeek.day.toString().padLeft(2, '0')}.${startOfWeek.month.toString().padLeft(2, '0')}.${startOfWeek.year.toString().substring(2)}";
    final String formattedEndDate = "${endOfWeek.day.toString().padLeft(2, '0')}.${endOfWeek.month.toString().padLeft(2, '0')}.${endOfWeek.year.toString().substring(2)}";
    final String dateRange = "$formattedStartDate-$formattedEndDate";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(dateRange, style:  TextStyle(color: customBlue, fontSize: 14)),
          const Spacer(),
          GestureDetector(
            onTap: _selectDate,
            child: Icon(Icons.calendar_today_outlined, size: 25, color: customBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final goalInSeconds = _goalMinutes * 60;
          final fillPercentage = (goalInSeconds > 0) ? (_displayedDailyTimes[index] / goalInSeconds).clamp(0.0, 1.0) : 0.0;
          bool isToday = _isSameWeek(_selectedDate, DateTime.now()) && (index == DateTime.now().weekday - 1);
          return _buildStatContainer(
            _formatTime(_displayedDailyTimes[index]),
            isToday ? customBlue : Colors.grey,
            fillPercentage,
          );
        }),
      ),
    );
  }

  Widget _buildDayLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          Text('Пн'), Text('Вт'), Text('Ср'), Text('Чт'), Text('Пт'), Text('Сб'), Text('Вс'),
        ],
      ),
    );
  }

  Widget _buildStatContainer(String text, Color color, double fillPercentage) {
    return SizedBox(
      width: 44,
      height: 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            height: 120 * fillPercentage,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultModes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text('Сохраненные режимы', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _allDefaultModes.length,
              itemBuilder: (context, index) {
                final mode = _allDefaultModes[index];
                return GestureDetector(
                  onTap: () async {
                    final selectedMode = _allDefaultModes[index];
                    final selectedModeName = selectedMode['modeName'] ?? selectedMode['name'];

                    // Update the isFavorite flag for all modes
                    for (var m in _allDefaultModes) {
                      final modeName = m['modeName'] ?? m['name'];
                      if (modeName == selectedModeName) {
                        m['isFavorite'] = true;
                      } else {
                        m['isFavorite'] = false;
                      }
                    }

                    // 4. Save everything back via ModeRepository (performs dedupe)
                    await ModeRepository.saveSavedModes(_allDefaultModes);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('favorite_mode', jsonEncode(selectedMode));
                    await prefs.setString('profile_selected_mode_name', selectedModeName);

                    // 5. Update the local UI.
                    setState(() {
                      _selectedModeIndex = index;
                    });
                  },
                  child: _buildUnifiedModeCard(
                    mode,
                    isSelected: _selectedModeIndex == index,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  // _buildAddModeCard removed (unused)

  Widget _buildUnifiedModeCard(Map<String, dynamic> mode, {required bool isSelected}) {
    // Prefer the normalized 'modeName' as the canonical display title.
    final String title = mode['modeName'] ?? mode['title'] ?? mode['name'] ?? 'Стандартный режим';
    final bool isIcon = mode['isIcon'] ?? false;

    final Color bgColor = isSelected ? customBlue : (mode['backgroundColor'] ?? Colors.white);
    final Color contentColor = isSelected ? Colors.white : (mode['textColor'] ?? Colors.black);
    final Color iconDataColor = isSelected ? Colors.white : Colors.black;

    Widget iconWidget;
    if (isIcon) {
      final dynamic iconValue = mode['icon'];
      IconData iconData;
      if (iconValue is int) {
        iconData = AppIcons.fromCodePoint(iconValue);
      } else {
        iconData = Icons.fitness_center; // Default icon if not an int
      }
      iconWidget = Icon(iconData, size: 55, color: iconDataColor);
    } else {
      if (mode['imagePath'] != null && (mode['imagePath'] as String).isNotEmpty) {
        iconWidget = Image.asset(
          mode['imagePath'],
          width: 45,
          height: 45,
          fit: BoxFit.contain,
          color: mode['backgroundColor'] == customBlue ? Colors.white : null,
        );
      } else {
        iconWidget = Icon(Icons.fitness_center, size: 55, color: iconDataColor);
      }
    }

   return Container(
  margin: const EdgeInsets.symmetric(horizontal: 5.0),
  width: 120,
  height: 130,
  decoration: BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children:[ iconWidget, ]
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: contentColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
        ),
      ],
    ),
  ),
);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProfileScreen(),
    );
  }
}