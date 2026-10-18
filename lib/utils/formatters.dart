String _two(int n) => n.toString().padLeft(2, '0');

/// 75 s -> "01:15"; 1 h 2 min -> "1:02:00".
String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) return '$hours:${_two(minutes)}:${_two(seconds)}';
  return '${_two(minutes)}:${_two(seconds)}';
}

/// "18/10/2026 · 21:05"
String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${_two(local.day)}/${_two(local.month)}/${local.year} · '
      '${_two(local.hour)}:${_two(local.minute)}';
}
