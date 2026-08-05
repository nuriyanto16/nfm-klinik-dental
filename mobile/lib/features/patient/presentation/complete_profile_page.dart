import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../application/session_controller.dart';
import '../data/patient_repository.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({
    super.key,
    this.initialEmail,
    this.initialName,
  });

  final String? initialEmail;
  final String? initialName;

  @override
  ConsumerState<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  DateTime? _dob;
  String _gender = 'male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.initialName ?? '');
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? 'user@gmail.com');
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995, 5, 20),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tanggal lahir Anda')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String phone = _phoneCtrl.text.trim();
      if (phone.startsWith('0')) {
        phone = '+62${phone.substring(1)}';
      } else if (phone.startsWith('62')) {
        phone = '+$phone';
      } else if (!phone.startsWith('+')) {
        phone = '+62$phone';
      }

      await ref.read(sessionControllerProvider.notifier).register(
            CreatePatientInput(
              fullName: _fullNameCtrl.text.trim(),
              relation: 'self',
              email: _emailCtrl.text.trim(),
              phoneWa: phone,
              dateOfBirth: DateFormat('yyyy-MM-dd').format(_dob!),
              gender: _gender,
              city: _cityCtrl.text.trim().isEmpty ? 'Bandung' : _cityCtrl.text.trim(),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil dilengkapi! Selamat datang di Nina Dental Care.'),
            backgroundColor: AppColors.pink,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Lengkapi Profil Akun', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Terhubung via Gmail SSO',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                            Text(
                              _emailCtrl.text,
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lengkapi Data Diri Anda 📋',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Untuk kemudahan rekam medis & reservasi klinik, mohon lengkapi profil berikut.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Nama Lengkap
                const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Budi Santoso',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Email (ReadOnly)
                const Text('Email Terdaftar (Gmail)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.green),
                    suffixIcon: const Icon(Icons.lock, size: 18, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),

                // No WhatsApp
                const Text('Nomor WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '081234567890',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nomor WhatsApp wajib diisi';
                    if (v.trim().length < 9) return 'Nomor WhatsApp tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Jenis Kelamin
                const Text('Jenis Kelamin', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.male, size: 18),
                            SizedBox(width: 6),
                            Text('Laki-laki'),
                          ],
                        ),
                        selected: _gender == 'male',
                        onSelected: (val) {
                          if (val) setState(() => _gender = 'male');
                        },
                        selectedColor: AppColors.pink.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.pink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.female, size: 18),
                            SizedBox(width: 6),
                            Text('Perempuan'),
                          ],
                        ),
                        selected: _gender == 'female',
                        onSelected: (val) {
                          if (val) setState(() => _gender = 'female');
                        },
                        selectedColor: AppColors.pink.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.pink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tanggal Lahir
                const Text('Tanggal Lahir', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _dob != null ? DateFormat('d MMMM yyyy', 'id_ID').format(_dob!) : 'Pilih Tanggal Lahir *',
                      style: TextStyle(
                        color: _dob != null ? AppColors.textDark : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kota
                const Text('Kota / Kabupaten Tempat Tinggal', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Bandung',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Kota tempat tinggal wajib diisi' : null,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Simpan Profil & Masuk Ke Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
