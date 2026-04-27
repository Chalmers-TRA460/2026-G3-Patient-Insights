class Patient {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final DateTime? dob;
  final String bloodType;
  final double height; // in cm
  final double weight; // in kg
  final List<String> conditions;
  final List<Map<String, String>> medications;
  final Map<String, dynamic> vitals;
  final Map<String, String>? emergencyContact;

  Patient({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.dob,
    this.bloodType = 'Unknown',
    this.height = 0,
    this.weight = 0,
    this.conditions = const [],
    this.medications = const [],
    this.vitals = const {},
    this.emergencyContact,
  });

  double get bmi {
    if (height <= 0 || weight <= 0) return 0;
    double h = height / 100;
    return weight / (h * h);
  }

  String get bmiStatus {
    double val = bmi;
    if (val <= 0) return 'Unknown';
    if (val < 18.5) return 'Underweight';
    if (val < 25) return 'Normal';
    if (val < 30) return 'Overweight';
    return 'Obese';
  }

  int get age {
    if (dob == null) return 0;
    final now = DateTime.now();
    int a = now.year - dob!.year;
    if (now.month < dob!.month ||
        (now.month == dob!.month && now.day < dob!.day)) {
      a--;
    }
    return a;
  }

  factory Patient.fromFirestore(Map<String, dynamic> data, String id) {
    return Patient(
      id: id,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      profileImage: data['profileImage'],
      dob: data['dob'] != null ? DateTime.tryParse(data['dob']) : null,
      bloodType: data['bloodType'] ?? 'Unknown',
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      conditions: List<String>.from(data['conditions'] ?? []),
      medications: List<Map<String, String>>.from(
        (data['medications'] ?? [])
            .map((item) => Map<String, String>.from(item)),
      ),
      vitals: Map<String, dynamic>.from(data['vitals'] ?? {}),
      emergencyContact: data['emergencyContact'] != null
          ? Map<String, String>.from(data['emergencyContact'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'dob': dob?.toIso8601String(),
      'bloodType': bloodType,
      'height': height,
      'weight': weight,
      'conditions': conditions,
      'medications': medications,
      'vitals': vitals,
      'emergencyContact': emergencyContact,
    };
  }
}
