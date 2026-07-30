import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local stand-in for real auth (see `docs/architecture.md` §5 — password
/// auth/JWT lands in Fase 1). "Registering" in this app just creates a
/// `identity.patients` row (self, no login required, matching how
/// `POST /patients` already works with `primaryAccountUserId` omitted) and
/// remembers its id here. Every screen that needs "who is this patient"
/// (booking, riwayat) reads it from here instead of a token.
class SessionStorage {
  SessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _patientIdKey = 'patient_id';
  static const _patientNameKey = 'patient_name';
  static const _patientPhoneKey = 'patient_phone';

  Future<PatientSession?> read() async {
    final id = await _storage.read(key: _patientIdKey);
    if (id == null || id.isEmpty) return null;
    final name = await _storage.read(key: _patientNameKey) ?? '';
    final phone = await _storage.read(key: _patientPhoneKey);
    return PatientSession(patientId: id, fullName: name, phoneWa: phone);
  }

  Future<void> save(PatientSession session) async {
    await _storage.write(key: _patientIdKey, value: session.patientId);
    await _storage.write(key: _patientNameKey, value: session.fullName);
    if (session.phoneWa != null) {
      await _storage.write(key: _patientPhoneKey, value: session.phoneWa);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _patientIdKey);
    await _storage.delete(key: _patientNameKey);
    await _storage.delete(key: _patientPhoneKey);
  }
}

class PatientSession {
  const PatientSession({required this.patientId, required this.fullName, this.phoneWa});

  final String patientId;
  final String fullName;
  final String? phoneWa;
}

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(const FlutterSecureStorage());
});
