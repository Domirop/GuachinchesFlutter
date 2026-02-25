class SurveyInAppChoice {
  final String value;
  final String text;

  SurveyInAppChoice({required this.value, required this.text});

  factory SurveyInAppChoice.fromJson(Map<String, dynamic> json) {
    return SurveyInAppChoice(
      value: json['value']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}
