// Standardized medical entry used across the patient profile (allergies,
// medications, diagnoses, past illnesses, implants, vaccinations).
//
// The `codedAnswer` field is intentionally nullable so a free-text patient
// entry can be captured today and later enriched with a SNOMED CT, ICD-10,
// ATC or similar code once mapping is available — keeping the schema
// forward-compatible with EHDS and FHIR (CodeableConcept) requirements.
class MedicalEntry {
  final String id;
  final String displayText;
  final String? codedAnswer;
  final DateTime dateAdded;
  final DateTime lastUpdated;
  final String source;
  // The clinically meaningful date for the entry (vaccine given, illness
  // experienced, implant placed). Distinct from dateAdded — that's only when
  // the patient typed this into the app. Maps to FHIR occurrence fields
  // (Immunization.occurrenceDateTime, Condition.onsetDateTime, etc.).
  final DateTime? occurredOn;

  MedicalEntry({
    required this.id,
    required this.displayText,
    this.codedAnswer,
    required this.dateAdded,
    required this.lastUpdated,
    this.source = 'patient_reported',
    this.occurredOn,
  });

  MedicalEntry copyWith({
    String? id,
    String? displayText,
    String? codedAnswer,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    String? source,
    DateTime? occurredOn,
  }) {
    return MedicalEntry(
      id: id ?? this.id,
      displayText: displayText ?? this.displayText,
      codedAnswer: codedAnswer ?? this.codedAnswer,
      dateAdded: dateAdded ?? this.dateAdded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      source: source ?? this.source,
      occurredOn: occurredOn ?? this.occurredOn,
    );
  }

  factory MedicalEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return MedicalEntry(
      id: (json['id'] as String?) ?? '',
      displayText: (json['displayText'] as String?) ?? '',
      codedAnswer: json['codedAnswer'] as String?,
      dateAdded: _parseDate(json['dateAdded']) ?? now,
      lastUpdated: _parseDate(json['lastUpdated']) ?? now,
      source: (json['source'] as String?) ?? 'patient_reported',
      occurredOn: _parseDate(json['occurredOn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayText': displayText,
      'codedAnswer': codedAnswer,
      'dateAdded': dateAdded.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'source': source,
      'occurredOn': occurredOn?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
