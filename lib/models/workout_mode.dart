// Removed unused import: Flutter material isn't required for this data-only model

class WorkoutMode {
  String name;
  String modeName; // This seems to be a duplicate of 'name' in some contexts, but I'll keep it for now as it's in the original data.
  dynamic icon; // Can be IconData.codePoint or imagePath
  bool isIcon; // true if icon is IconData.codePoint, false if it's an imagePath
  String? imagePath; // Path to asset image if isIcon is false

  int totalExercises;
  int exerciseDuration; // in seconds
  int exerciseBreak; // in seconds
  int roundDuration; // in number of rounds, not time
  int roundBreak; // in seconds

  bool isFavorite;
  bool isStandardMode; // Flag to identify the original standard mode template

  // Runtime properties (not saved)
  int currentExercise;
  int currentRound;
  int remainingTime;
  bool isBreakTime;
  bool isRoundBreakTime;
  int sessionSeconds;

  WorkoutMode({
    required this.name,
    required this.modeName,
    this.icon,
    this.isIcon = true,
    this.imagePath,
    this.totalExercises = 5,
    this.exerciseDuration = 30,
    this.exerciseBreak = 10,
    this.roundDuration = 5,
    this.roundBreak = 30,
    this.isFavorite = false,
    this.isStandardMode = false,
    this.currentExercise = 1,
    this.currentRound = 1,
    this.remainingTime = 30,
    this.isBreakTime = false,
    this.isRoundBreakTime = false,
    this.sessionSeconds = 0,
  });

  // Factory constructor for creating a WorkoutMode from a JSON map
  factory WorkoutMode.fromJson(Map<String, dynamic> json) {
    return WorkoutMode(
      name: json['name'] as String,
      modeName: json['modeName'] as String,
      icon: json['icon'], // Will be int (codePoint) or String (imagePath)
      isIcon: json['isIcon'] as bool,
      imagePath: json['imagePath'] as String?,
      totalExercises: json['totalExercises'] as int,
      exerciseDuration: json['exerciseDuration'] as int,
      exerciseBreak: json['exerciseBreak'] as int,
      roundDuration: json['roundDuration'] as int,
      roundBreak: json['roundBreak'] as int,
      isFavorite: json['isFavorite'] as bool,
      isStandardMode: json['isStandardMode'] as bool? ?? false, // Default to false for old modes
      // Runtime properties are not loaded from JSON, they start with default values
    );
  }

  // Method for converting a WorkoutMode to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'modeName': modeName,
      'icon': icon,
      'isIcon': isIcon,
      'imagePath': imagePath,
      'totalExercises': totalExercises,
      'exerciseDuration': exerciseDuration,
      'exerciseBreak': exerciseBreak,
      'roundDuration': roundDuration,
      'roundBreak': roundBreak,
      'isFavorite': isFavorite,
      'isStandardMode': isStandardMode,
    };
  }

  // Method to create a deep copy of the WorkoutMode object
  WorkoutMode copyWith({
    String? name,
    String? modeName,
    dynamic icon,
    bool? isIcon,
    String? imagePath,
    int? totalExercises,
    int? exerciseDuration,
    int? exerciseBreak,
    int? roundDuration,
    int? roundBreak,
    bool? isFavorite,
    bool? isStandardMode,
  }) {
    return WorkoutMode(
      name: name ?? this.name,
      modeName: modeName ?? this.modeName,
      icon: icon ?? this.icon,
      isIcon: isIcon ?? this.isIcon,
      imagePath: imagePath ?? this.imagePath,
      totalExercises: totalExercises ?? this.totalExercises,
      exerciseDuration: exerciseDuration ?? this.exerciseDuration,
      exerciseBreak: exerciseBreak ?? this.exerciseBreak,
      roundDuration: roundDuration ?? this.roundDuration,
      roundBreak: roundBreak ?? this.roundBreak,
      isFavorite: isFavorite ?? this.isFavorite,
      isStandardMode: isStandardMode ?? this.isStandardMode,
      // Runtime properties are not copied, they start with default values
    );
  }
}
