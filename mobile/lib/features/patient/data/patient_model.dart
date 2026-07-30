class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    this.rmNumber,
    required this.relation,
    this.gender,
    this.dateOfBirth,
    this.phoneWa,
    this.email,
    this.city,
    this.address,
  });

  final String id;
  final String fullName;
  final String? rmNumber;
  final String relation;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? phoneWa;
  final String? email;
  final String? city;
  final String? address;

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        rmNumber: json['rmNumber'] as String?,
        relation: json['relation'] as String,
        gender: json['gender'] as String?,
        dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth'] as String) : null,
        phoneWa: json['phoneWa'] as String?,
        email: json['email'] as String?,
        city: json['city'] as String?,
        address: json['address'] as String?,
      );
}
