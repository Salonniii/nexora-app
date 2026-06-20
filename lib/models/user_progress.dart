class UserProgress {
  int xp;
  int streak;

  UserProgress({
    required this.xp,
    required this.streak,
  });

  int get level => (xp ~/ 500) + 1;
}