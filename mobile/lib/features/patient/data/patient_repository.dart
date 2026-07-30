import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'patient_model.dart';

class CreatePatientInput {
  const CreatePatientInput({
    required this.fullName,
    required this.relation,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.email,
    this.phoneWa,
    this.city,
  });

  final String fullName;
  final String relation;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? email;
  final String? phoneWa;
  final String? city;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'relation': relation,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'email': email,
        'phoneWa': phoneWa,
        'city': city,
      };
}

class PatientRepository {
  PatientRepository(this._dio);

  final Dio _dio;

  Future<Patient> createPatient(CreatePatientInput input) async {
    final res = await _dio.post<Map<String, dynamic>>('/patients', data: input.toJson());
    return Patient.fromJson(res.data!);
  }
}

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(dioProvider));
});
