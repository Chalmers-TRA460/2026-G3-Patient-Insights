class VisitSubQuestion {
  final String id;
  final String label;
  const VisitSubQuestion(this.id, this.label);
}

class VisitCategory {
  final String id;
  final String label;
  final List<VisitSubQuestion> subQuestions;
  const VisitCategory(this.id, this.label, {this.subQuestions = const []});
}

const List<VisitCategory> kVisitTaxonomy = [
  VisitCategory('pain', 'Pain or discomfort', subQuestions: [
    VisitSubQuestion('pain.location', 'Where is the pain?'),
    VisitSubQuestion('pain.severity', 'How severe is it? (1–10)'),
    VisitSubQuestion('pain.type', 'How would you describe it? (sharp, dull, burning…)'),
    VisitSubQuestion('pain.triggers', 'What makes it better or worse?'),
  ]),
  VisitCategory('fever', 'Fever or chills', subQuestions: [
    VisitSubQuestion('fever.temperature', 'What is your temperature?'),
    VisitSubQuestion('fever.other', 'Any other symptoms alongside the fever?'),
  ]),
  VisitCategory('fatigue', 'Fatigue or low energy', subQuestions: [
    VisitSubQuestion('fatigue.sleep', 'Is it affecting your sleep?'),
    VisitSubQuestion('fatigue.rest', 'Does rest help at all?'),
  ]),
  VisitCategory('breathing', 'Breathing difficulties', subQuestions: [
    VisitSubQuestion('breathing.when', 'Does it happen at rest or during activity?'),
    VisitSubQuestion('breathing.chest', 'Any chest tightness or pain?'),
  ]),
  VisitCategory('nausea', 'Nausea or digestive issues', subQuestions: [
    VisitSubQuestion('nausea.type', 'Nausea, vomiting, or diarrhoea?'),
    VisitSubQuestion('nausea.appetite', 'Has your appetite changed?'),
  ]),
  VisitCategory('skin', 'Skin changes', subQuestions: [
    VisitSubQuestion('skin.location', 'Where on your body?'),
    VisitSubQuestion('skin.appearance', 'Any itching, redness, or rash?'),
  ]),
  VisitCategory('mental', 'Mental health or mood', subQuestions: [
    VisitSubQuestion('mental.type', 'Are you feeling anxious or down?'),
    VisitSubQuestion('mental.impact', 'Is it affecting your daily life?'),
  ]),
  VisitCategory('followup', 'Follow-up visit', subQuestions: [
    VisitSubQuestion('followup.condition', 'Which condition or treatment is this for?'),
    VisitSubQuestion('followup.new_symptoms', 'Any new symptoms since your last visit?'),
  ]),
  VisitCategory('other', 'Something else', subQuestions: [
    VisitSubQuestion('other.description', 'Can you describe what you are experiencing?'),
  ]),
];

// Maps the old flat visit-reason labels to taxonomy IDs for legacy record loading.
const Map<String, String> kLegacyReasonToId = {
  'Pain or discomfort': 'pain',
  'Fever or chills': 'fever',
  'Fatigue or low energy': 'fatigue',
  'Breathing difficulties': 'breathing',
  'Nausea or digestive issues': 'nausea',
  'Skin changes': 'skin',
  'Mental health or mood': 'mental',
  'Follow-up visit': 'followup',
  'Something else': 'other',
};
