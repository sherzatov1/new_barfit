import 'package:flutter/material.dart';

class Mode {
  String name;
  IconData icon;
  int totalExercises;
  int exerciseDuration;
  int exerciseBreak;
  int roundCount;
  int roundBreak;
  int totalWorkTime;
  int currentExercise;
  int currentRound;
  int remainingTime;
  bool isBreakTime;
  bool isRoundBreakTime;
  int sessionSeconds;
  bool isFavorite;
  bool isIcon; // This seems to be a flag, not an actual icon. Consider renaming if it's not about the icon itself.
  bool filled; // For UI state, if the card is "filled" or selected

  Mode({
    required this.name,
    required this.icon,
    this.totalExercises = 5,
    this.exerciseDuration = 30,
    this.exerciseBreak = 10,
    this.roundCount = 5,
    this.roundBreak = 30,
    this.totalWorkTime = 0,
    this.currentExercise = 1,
    this.currentRound = 1,
    this.remainingTime = 30,
    this.isBreakTime = false,
    this.isRoundBreakTime = false,
    this.sessionSeconds = 0,
    this.isFavorite = false,
    this.isIcon = true,
    this.filled = false,
  });

  // Factory constructor to create a Mode object from a JSON map
  factory Mode.fromJson(Map<String, dynamic> json) {
    return Mode(
      name: json['name'] ?? json['modeName'] ?? 'Быстрый режим',
      icon: IconData(json['icon'] ?? Icons.sports_mma.codePoint, fontFamily: 'MaterialIcons'),
      totalExercises: json['totalExercises'] ?? 5,
      exerciseDuration: json['exerciseDuration'] ?? 30,
      exerciseBreak: json['exerciseBreak'] ?? 10,
      roundCount: json['roundCount'] ?? 5,
      roundBreak: json['roundBreak'] ?? 30,
      totalWorkTime: json['totalWorkTime'] ?? 0,
      currentExercise: json['currentExercise'] ?? 1,
      currentRound: json['currentRound'] ?? 1,
      remainingTime: json['remainingTime'] ?? 30,
      isBreakTime: json['isBreakTime'] ?? false,
      isRoundBreakTime: json['isRoundBreakTime'] ?? false,
      sessionSeconds: json['sessionSeconds'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      isIcon: json['isIcon'] ?? true,
      filled: json['filled'] ?? false,
    );
  }

  // Method to convert a Mode object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'modeName': name, // Keep for backward compatibility if needed
      'icon': icon.codePoint,
      'totalExercises': totalExercises,
      'exerciseDuration': exerciseDuration,
      'exerciseBreak': exerciseBreak,
      'roundCount': roundCount,
      'roundBreak': roundBreak,
      'totalWorkTime': totalWorkTime,
      'currentExercise': currentExercise,
      'currentRound': currentRound,
      'remainingTime': remainingTime,
      'isBreakTime': isBreakTime,
      'isRoundBreakTime': isRoundBreakTime,
      'sessionSeconds': sessionSeconds,
      'isFavorite': isFavorite,
      'isIcon': isIcon,
      'filled': filled,
    };
  }

  // Helper to calculate total work time
  int calculateTotalWorkTime() {
    return exerciseDuration * totalExercises * roundCount;
  }
}
