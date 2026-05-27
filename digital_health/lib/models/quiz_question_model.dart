class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final bool notMentioned;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.notMentioned = false,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? []),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
      notMentioned: json['notMentioned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'notMentioned': notMentioned,
      };

  QuizQuestion copyWith({
    String? question,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    bool? notMentioned,
  }) {
    return QuizQuestion(
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      notMentioned: notMentioned ?? this.notMentioned,
    );
  }
}
