class VHIQuestion {
  final int number;
  final String text;
  final String subscale; // 'functional', 'physical', or 'emotional'

  VHIQuestion({
    required this.number,
    required this.text,
    required this.subscale,
  });
}
