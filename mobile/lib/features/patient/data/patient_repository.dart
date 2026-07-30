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
    this.primaryAccountUserId,
  });

  final String fullName;
  final String relation;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? email;
  final String? phoneWa;
  final String? city;
  final String? primaryAccountUserId;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'relation': relation,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'email': email,
        'phoneWa': phoneWa,
        'city': city,
        'primaryAccountUserId': primaryAccountUserId,
      };
}

class PatientRepository {
  PatientRepository(this._dio);

  final Dio _dio;

  Future<Patient> createPatient(CreatePatientInput input) async {
    final res = await _dio.post<Map<String, dynamic>>('/patients', data: input.toJson());
    return Patient.fromJson(res.data!);
  }

  /// Full patient list (no `page`/`pageSize` query params — core-api's
  /// pagination is opt-in, so omitting them returns a plain array here
  /// instead of the paginated envelope the admin panel uses).
  Future<List<Patient>> listAll() async {
    final res = await _dio.get<List<dynamic>>('/patients');
    return (res.data ?? []).map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(ref.watch(dioProvider));
});
