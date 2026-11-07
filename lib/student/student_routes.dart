class StudentRoutes {
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String quizzes = '/quizzes';
  static const String recordings = '/recordings';
  static const String settings = '/settings';

  static const String leaderboard = '$quizzes/leaderboard';

  static const String announcements = '$home/announcements';

  static String quiz(String quizId) => '$quizzes/$quizId';

  static String takeQuiz(String quizId) => '$quizzes/$quizId/take';

  static String quizResult(String quizId, int attemptNumber) => '$quizzes/$quizId/result/$attemptNumber';

  /// Opens the leaderboard on one quiz; without a quiz it opens on the overall ranking.
  static String quizLeaderboard(String quizId) => '$leaderboard?quiz=$quizId';
}
