import 'package:flutter/material.dart';
import 'package:new_barfit/mode_screen_logic.dart';
import 'package:new_barfit/widgets/mode_tile.dart';
import 'package:new_barfit/services/mode_repository.dart';
import 'package:new_barfit/settings_screen.dart';
import 'package:provider/provider.dart';

class ModesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> savedModes;
  final Function(Map<String, dynamic>) onDeleteMode;
  final Function() onModesChanged;

  const ModesScreen({
    Key? key,
    required this.savedModes,
    required this.onDeleteMode,
    required this.onModesChanged,
  }) : super(key: key);

  @override
  State<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends State<ModesScreen> {
  late ModeScreenController _controller;

  @override
  void initState() {
    super.initState();
    _loadModesFromRepository();
  }

  Future<void> _loadModesFromRepository() async {
    final loaded = await ModeRepository.loadSavedModes();
    setState(() {
      _controller = ModeScreenController(
        savedModes: loaded,
        onDeleteMode: widget.onDeleteMode,
        onModesChanged: _reloadModes,
      );
      _controller.loadInitialSelection();
    });
  }

  void _reloadModes() async {
    await _loadModesFromRepository();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ModesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadModesFromRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadModesFromRepository();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ModeScreenController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Создать новый режим',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(modeName: ''),
                  ),
                ).then((_) {
                  _controller.onModesChanged();
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Consumer<ModeScreenController>(
              builder: (context, controller, child) {
                if (controller.savedModes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Нет режимов',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить режим'),
                          onPressed: () => controller.showAddModeDialog(context),
                        ),
                      ],
                    ),
                  );
                } else {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      double width = constraints.maxWidth;
                      int crossAxisCount = 2;
                      if (width > 1200) {
                        crossAxisCount = 5;
                      } else if (width > 900) {
                        crossAxisCount = 4;
                      } else if (width > 600) {
                        crossAxisCount = 3;
                      }
                      double spacing = width * 0.02;
                      double cardWidth = (width - spacing * (crossAxisCount - 1)) / crossAxisCount;
                      double cardHeight = cardWidth * 1.10;

                      return GridView.builder(
                        itemCount: controller.savedModes.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final mode = controller.savedModes[index];
                          return GestureDetector(
                            onTap: () {
                              controller.selectedIndex = index;
                              ModeRepository.setActiveMode(mode);
                            },
                            onLongPress: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SettingsScreen(
                                    modeName: mode['modeName'] ?? mode['name'] ?? '',
                                    iconCodePoint: mode['icon'] as int?,
                                  ),
                                ),
                              ).then((_) {
                                controller.onModesChanged();
                              });
                            },
                            child: SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: ModeDataContainer(
                                mode,
                                isSelected: controller.selectedIndex == index,
                                index: index,
                                controller: controller,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
