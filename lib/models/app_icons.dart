import 'package:flutter/material.dart';

class AppIcons {
  // The single source of truth for all workout mode icons.
  static const List<IconData> modeIcons = [
    Icons.sports_mma,
    Icons.directions_run,
    Icons.fitness_center,
    Icons.sports_kabaddi,
    Icons.sports_handball,
    Icons.sports_basketball,
    Icons.sports_football,
    Icons.sports_tennis,
    Icons.sports_volleyball,
    Icons.sports_baseball,
    Icons.sports_cricket,
    Icons.sports_golf,
    Icons.sports_hockey,
    Icons.sports_motorsports,
    Icons.sports_soccer,
    Icons.timer,
  ];

  /// Safely retrieves an icon from its code point.
  ///
  /// Returns a default icon if the code point is not found in the list.
  static IconData fromCodePoint(int codePoint) {
    return modeIcons.firstWhere(
      (icon) => icon.codePoint == codePoint,
      orElse: () => Icons.fitness_center, // Default icon
    );
  }
}
