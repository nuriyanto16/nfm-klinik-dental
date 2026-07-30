import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/session_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../application/session_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider).value;
    _nameCtrl = TextEditingController(text: session?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: session?.phoneWa ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = ref.read(sessionControllerProvider).value;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi tidak ditemukan. Silakan daftar/masuk kembali.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Local session cache only — core-api's patient update endpoint
      // doesn't accept phone/email/city yet (see UpdatePatientInput), so
      // this doesn't sync back to the office record. Name changes here
      // are cosmetic until that's added.
      final updated = PatientSession(
        patientId: session.patientId,
        fullName: _nameCtrl.text.trim(),
        phoneWa: _phoneCtrl.text.trim(),
      );
      await ref.read(sessionStorageProvider).save(updated);
      ref.invalidate(sessionControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _nameCtrl),
            const SizedBox(height: 16),
            const Text('Nomor WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            const Text('Kota/Kabupaten', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: _cityCtrl),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
