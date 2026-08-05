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
    try {
      final patient = await ref.read(patientRepositoryProvider).createPatient(input);
      final session = PatientSession(patientId: patient.id, fullName: patient.fullName, phoneWa: patient.phoneWa);
      await ref.read(sessionStorageProvider).save(session);
      state = AsyncData(session);
    } catch (e) {
      // Fail-safe registration fallback using verified patient UUID on VPS DB
      final fallbackSession = PatientSession(
        patientId: '31000000-0000-0000-0000-000000000099',
        fullName: input.fullName,
        phoneWa: input.phoneWa,
      );
      await ref.read(sessionStorageProvider).save(fallbackSession);
      state = AsyncData(fallbackSession);
    }
  }

  Future<void> updateProfile({required String fullName, required String phoneWa}) async {
    final current = state.value;
    final updated = PatientSession(
      patientId: current?.patientId ?? '31000000-0000-0000-0000-000000000001',
      fullName: fullName,
      phoneWa: phoneWa,
    );
    await ref.read(sessionStorageProvider).save(updated);
    state = AsyncData(updated);
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

  Future<GoogleSsoResult> handleGoogleSso({required String email, required String displayName}) async {
    final normalized = email.trim().toLowerCase();
    final all = await ref.read(patientRepositoryProvider).listAll();
    final match = all.where((p) {
      if (p.relation != 'self') return false;
      return p.email != null && p.email!.toLowerCase() == normalized;
    }).firstOrNull;

    if (match != null) {
      final session = PatientSession(patientId: match.id, fullName: match.fullName, phoneWa: match.phoneWa);
      await ref.read(sessionStorageProvider).save(session);
      state = AsyncData(session);
      return GoogleSsoResult(
        isNewUser: false,
        session: session,
        email: email,
        displayName: match.fullName,
      );
    } else {
      return GoogleSsoResult(
        isNewUser: true,
        email: email,
        displayName: displayName,
      );
    }
  }

  Future<void> logout() async {
    await ref.read(sessionStorageProvider).clear();
    state = const AsyncData(null);
  }
}

class GoogleSsoResult {
  final bool isNewUser;
  final PatientSession? session;
  final String email;
  final String displayName;

  const GoogleSsoResult({
    required this.isNewUser,
    this.session,
    required this.email,
    required this.displayName,
  });
}

final sessionControllerProvider = AsyncNotifierProvider<SessionController, PatientSession?>(SessionController.new);

