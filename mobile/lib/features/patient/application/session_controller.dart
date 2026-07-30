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

  Future<void> logout() async {
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, PatientSession?>(SessionController.new);
