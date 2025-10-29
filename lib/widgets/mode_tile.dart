import 'package:flutter/material.dart';
import 'package:new_barfit/mode_screen_logic.dart';
import 'package:new_barfit/models/app_icons.dart';

// Public widget extracted from ModesScreen: displays mode card and its rows
class ModeDataContainer extends StatelessWidget {
  final Map<String, dynamic> modeData;
  final bool isSelected;
  final int index;
  final ModeScreenController controller;

  const ModeDataContainer(
    this.modeData, {
    Key? key,
    required this.isSelected,
    required this.index,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = modeData['modeName'] ?? modeData['name'] ?? 'Быстрый режим';

    final int exerciseCount = modeData['totalExercises'] ?? 5;
    final int exerciseDuration = modeData['exerciseDuration'] ?? 30;
    final int exerciseBreak = modeData['exerciseBreak'] ?? 10;
    final int roundBreak = modeData['roundBreak'] ?? 30;

    final int workInCircleSeconds = exerciseCount * exerciseDuration;
    final String workInCircleString = controller.formatDuration(workInCircleSeconds);

    final int totalRestInCircle = ((exerciseCount > 1) ? (exerciseCount - 1) * exerciseBreak : 0) + roundBreak;
    final String totalRestInCircleString = controller.formatDuration(totalRestInCircle);

    final dynamic iconValue = modeData['icon'];
    IconData icon;

    if (iconValue is int) {
      icon = AppIcons.fromCodePoint(iconValue);
    } else {
      icon = AppIcons.modeIcons[0];
    }

    final Color iconColor = modeData['iconColor'] ?? Colors.black;
    final bool filled = isSelected || (modeData['filled'] ?? false);

    final String? bottomValue = modeData['bottomValue'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double iconSize = cardWidth * 0.13;
        final double circleSize = cardWidth * 0.18;
        final double fontSize = cardWidth * 0.09;
        final double rowIconSize = cardWidth * 0.07;
        final double rowFontSize = cardWidth * 0.06;

        return Container(
          constraints: const BoxConstraints(minHeight: 140),
          padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05, vertical: cardWidth * 0.05),
          decoration: BoxDecoration(
            color: isSelected || (modeData['filled'] ?? false) ? null : Colors.white,
            gradient: isSelected || (modeData['filled'] ?? false)
                ? const LinearGradient(
                    colors: [Color(0xFF3887FE), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(cardWidth * 0.09),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(icon, size: iconSize, color: filled ? Colors.white : iconColor),
                    onPressed: () => controller.selectIcon(context, index),
                    splashRadius: iconSize * 0.7,
                    tooltip: 'Выбрать иконку',
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => controller.showDeleteConfirmationDialog(context, modeData),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.bookmark,
                            size: iconSize * 0.8,
                            color: filled ? Colors.white : Colors.blue,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => controller.toggleFavorite(context, index),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            (modeData['isFavorite'] ?? false) ? Icons.star : Icons.star_border,
                            size: iconSize * 0.8,
                            color: filled ? Colors.white : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              controller.editingIndex == index
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        autofocus: true,
                        controller: controller.textEditingController,
                        onSubmitted: (_) => controller.saveEditing(index),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: filled ? Colors.white : Colors.black,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: 1,
                      ),
                    )
                  : GestureDetector(
                      onTap: () => controller.startEditing(index, name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                            color: filled ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
              SizedBox(height: cardWidth * 0.02),
              Padding(
                padding: EdgeInsets.only(left: cardWidth * 0.05, right: cardWidth * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: cardWidth * 0.05, bottom: cardWidth * 0.02),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            filled ? 'assets/cercleone.png' : 'assets/whitecir1.png',
                            width: circleSize,
                            height: circleSize,
                          ),
                          SizedBox(height: cardWidth * 0.02),
                          Image.asset(
                            filled ? 'assets/circletwo.png' : 'assets/whitecir2.png',
                            width: circleSize * 0.9,
                            height: circleSize * 0.9,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: cardWidth * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ModeRow(
                            icon: Icons.timer,
                            text: workInCircleString,
                            filled: filled,
                            iconSize: rowIconSize,
                            fontSize: rowFontSize,
                            maxLines: 2,
                          ),
                          ModeRow(
                            icon: Icons.pause_circle_filled,
                            text: totalRestInCircleString,
                            filled: filled,
                            faded: true,
                            iconSize: rowIconSize,
                            fontSize: rowFontSize,
                            maxLines: 2,
                          ),
                          SizedBox(height: cardWidth * 0.012),
                          ModeRow(
                            icon: Icons.av_timer,
                            text: '${modeData['exerciseDuration'] ?? 30} сек',
                            filled: filled,
                            faded: true,
                            iconSize: rowIconSize,
                            fontSize: rowFontSize,
                          ),
                          ModeRow(
                            icon: Icons.pause_circle_filled,
                            text: '${modeData['exerciseBreak'] ?? 10} сек',
                            filled: filled,
                            faded: true,
                            iconSize: rowIconSize,
                            fontSize: rowFontSize,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: cardWidth * 0.018),
              if (bottomValue != null)
                Center(
                  child: Text(
                    bottomValue,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: fontSize * 0.8,
                      color: filled ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ModeRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool filled;
  final bool faded;
  final double iconSize;
  final double fontSize;
  final int? maxLines;
  const ModeRow({
    Key? key,
    required this.icon,
    required this.text,
    this.filled = false,
    this.faded = false,
    this.iconSize = 16,
    this.fontSize = 13,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: faded
                ? (filled ? Colors.white70 : Colors.black54)
                : (filled ? Colors.white : Colors.black87),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: faded
                    ? (filled ? Colors.white70 : Colors.black54)
                    : (filled ? Colors.white : Colors.black87),
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
