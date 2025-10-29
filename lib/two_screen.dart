// ignore_for_file: unused_field

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TwoScreen extends StatefulWidget {
  const TwoScreen({super.key});

  @override
  State<TwoScreen> createState() => _TwoScreenState();
}

class _TwoScreenState extends State<TwoScreen> {
  String? _loadingAction;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showCustomDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ОК',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    _showCustomDialog(
      title: 'Политика конфиденциальности',
      content:
          'Эта Политика конфиденциальности объясняет, как Bar Fit (далее — «Приложение») собирает, использует, хранит и защищает вашу информацию. '
          'Пользуясь Приложением, вы соглашаетесь с условиями этой политики.\n\n'
          'Сбор и использование информации\n'
          '• Личная информация: мы собираем данные при регистрации — имя, email, дата рождения и др.\n'
          '• Данные о здоровье: тренировки, цели, вес, рост и т.д.\n'
          '• Устройство: тип, ОС, ID.\n'
          '• Использование: история действий, статистика.\n\n'
          'Передача данных\n'
          'Может передаваться сервисам (например, Virtuagym) или по закону — в зашифрованном виде.\n\n'
          'Безопасность данных\n'
          'Мы шифруем данные и защищаем их от доступа.\n\n'
          'Ваши права\n'
          'Вы можете запросить удаление или исправление данных через службу поддержки.',
    );
  }

  void _showTermsDialog() {
    _showCustomDialog(
      title: 'Правила пользования',
      content:
          'Общие положения\n Эти Правила регулируют использование Bar Fit. Пользуясь Приложением, вы соглашаетесь с ними.\n\n'
          'Услуги:\n• Расписание занятий\n• Бронирование встреч\n• Отслеживание прогресса\n• Программы тренировок\n\n'
          'Учетная запись\nВы несёте ответственность за свою учётную запись.\n\n'
          'Ответственность пользователя\n'
          'Вы обязаны:\n• Указывать точную информацию\n• Соблюдать законы\n• Не совершать незаконные действия\n\n'
          'Отказ от ответственности\n'
          'Приложение предоставляется «как есть». Мы не несем ответственности за убытки.',
    );
  }

  void _showAboutDialog() {
    _showCustomDialog(
      title: 'О приложении',
      content:
          'Bar Fit — это комплексное приложение для здоровья и фитнеса, разработанное, чтобы помочь вам достичь ваших целей. '
          'Независимо от того, занимаетесь ли вы в группе или индивидуально, наше Приложение делает ваш путь к лучшей версии себя ещё проще.\n\n'
          'Основные функции:\n'
          '• Расписание и бронирование\n'
          '• Отслеживание прогресса\n'
          '• Индивидуальные планы с 3D-демонстрациями\n\n'
          'Bar Fit — ваш помощник в здоровом образе жизни.',
    );
  }

  Future<void> _saveProgress() async {
    setState(() => _loadingAction = 'save');
    _showMessage('Сохраняем прогресс локально...');
    try {
      final String savedPath = await LocalBackup.saveProgress();
      _showMessage('Прогресс сохранён: $savedPath');
    } catch (e) {
      _showMessage('Ошибка при сохранении: $e. Проверьте разрешения для приложения.');
    }
    setState(() => _loadingAction = null);
  }

  Future<void> _loadProgress() async {
    setState(() => _loadingAction = 'load');
    _showMessage('Загружаем прогресс из локальной копии...');
    try {
      bool success = await LocalBackup.loadProgress();
      if (success) {
        _showMessage('Прогресс успешно загружен! Перезапустите приложение.');
      } else {
        _showMessage('Резервная копия не найдена.');
      }
    } catch (e) {
      _showMessage('Ошибка при загрузке: $e');
    }
    setState(() => _loadingAction = null);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardWidth = screenWidth * 0.92 < 370 ? screenWidth * 0.92 : 370;
    final double cardHeight = 84;
    final double spacing = screenHeight * 0.018;
    final double titleFont = screenWidth > 500 ? 38 : 28;
    final double buttonFont = screenWidth > 500 ? 24 : 18;
    final double iconSize = screenWidth > 500 ? 36 : 28;

    Widget buildClickableText(String text, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: spacing + 8),
                  Text(
                    'Настройки',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFont),
                  ),
                  SizedBox(height: spacing + 5),
                  ElevatedButton(
                    onPressed: _loadingAction != null ? null : _saveProgress,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(cardWidth, cardHeight),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_download_outlined, size: iconSize, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Сохранить прогресс',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: buttonFont,
                            color: Colors.white,
                          ),
                        ),
                        if (_loadingAction == 'save') const SizedBox(width: 12),
                        if (_loadingAction == 'save')
                          const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3)),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing),
                  ElevatedButton(
                    onPressed: _loadingAction != null ? null : _loadProgress,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(cardWidth, cardHeight),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_download_sharp, size: iconSize, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Загрузить прогресс',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: buttonFont,
                            color: Colors.white,
                          ),
                        ),
                        if (_loadingAction == 'load') const SizedBox(width: 12),
                        if (_loadingAction == 'load')
                          const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3)),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing * 23),
                  SizedBox(height: spacing),
                  buildClickableText('Политика конфиденциальности', _showPrivacyDialog),
                  buildClickableText('Правила пользования', _showTermsDialog),
                  buildClickableText('О приложении', _showAboutDialog),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LocalBackup {
  static const _backupFileName = 'bar_fitness_backup.json';

  static Future<String> _getDownloadsPath() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/BarFitnessBackup');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir.path;
    } else if (Platform.isIOS) {
      // Для iOS файлы сохраняются в папку "Документы" приложения.
      directory = await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("Unsupported platform");
    }

  return directory.path;
  }

  static Future<File> _getBackupFile() async {
    final path = await _getDownloadsPath();
    return File('$path/$_backupFileName');
  }

  static Future<String> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final allData = <String, dynamic>{};
    for (var key in prefs.getKeys()) {
      allData[key] = prefs.get(key);
    }
    final backupJson = jsonEncode(allData);
    final file = await _getBackupFile();
    await file.writeAsString(backupJson);
    return file.path;
  }

  static Future<bool> loadProgress() async {
    try {
      final file = await _getBackupFile();
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final Map<String, dynamic> loadedData = jsonDecode(content);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      for (var key in loadedData.keys) {
        final value = loadedData[key];
        if (value is String) await prefs.setString(key, value);
        else if (value is int) await prefs.setInt(key, value);
        else if (value is double) await prefs.setDouble(key, value);
        else if (value is bool) await prefs.setBool(key, value);
        else if (value is List) await prefs.setStringList(key, value.cast<String>());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}