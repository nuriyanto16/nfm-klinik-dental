import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/session_storage.dart';
import '../data/patient_repository.dart';

/// The current "who's using this app" state. There's no password login yet
/// (see `docs/architecture.md` §5) — registering just creates an
/// `identity.patients` row and remembers its id, see `SessionStorage`.
class SessionController extends AsyncNotifier<PatientSession?> {
  @override
  Future<PatientSession?> build() {
    return ref.watch(sessionStorageProvider).read();
  }

  Future<void> register(CreatePatientInput input) async {
    final patient = await ref.read(patientRepositoryProvider).createPatient(input);
    final session = PatientSession(patientId: patient.id, fullName: patient.fullName, phoneWa: patient.phoneWa);
    await ref.read(sessionStorageProvider).save(session);
    state = AsyncData(session);
  }

  /// Finds a real, already-registered "self" patient by email or WhatsApp
  /// number and adopts it as the session — there's no password check yet
  /// (see class doc), so this only proves the identifier is a real account,
  /// not that this specific person owns it.
  Future<void> login(String identifier) async {
    final normalized = identifier.trim().toLowerCase();
    final digits = identifier.replaceAll(RegExp(r'\D'), '');
    final all = await ref.read(patientRepositoryProvider).listAll();
    final match = all.where((p) {
      if (p.relation != 'self') return false;
      if (p.email != null && p.email!.toLowerCase() == normalized) return true;
      if (p.phoneWa != null && digits.isNotEmpty) {
        final storedDigits = p.phoneWa!.replaceAll(RegExp(r'\D'), '');
        return storedDigits.endsWith(digits) || digits.endsWith(storedDigits);
      }
      return false;
    }).firstOrNull;

    if (match == null) {
      throw Exception('Akun tidak ditemukan. Silakan daftar terlebih dahulu.');
    }

    final session = PatientSession(patientId: match.id, fullName: match.fullName, phoneWa: match.phoneWa);
    await ref.read(sessionStorageProvider).save(session);
    state = AsyncData(session);
  }

  Future<void> logout() async {
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, PatientSession?>(SessionController.new);
