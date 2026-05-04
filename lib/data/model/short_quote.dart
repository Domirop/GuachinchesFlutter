class ShortQuote {
  final String text;
  final bool isWarning;
  final String? timestamp;

  const ShortQuote({required this.text, this.isWarning = false, this.timestamp});

  factory ShortQuote.fromJson(Map<String, dynamic> json) => ShortQuote(
        text: json['text']?.toString() ?? '',
        isWarning: json['isWarning'] == true,
        timestamp: json['timestamp']?.toString(),
      );
}
