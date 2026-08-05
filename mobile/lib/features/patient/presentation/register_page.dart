import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../application/session_controller.dart';
import '../data/patient_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  DateTime? _dob;
  String _gender = 'male';
  bool _isLoading = false;
  bool _phoneValid = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 11, 16),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // DOB is optional — if user skips, we leave it null (API accepts null)
    // Previously this blocked registration with a confusing error.

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
              dateOfBirth: _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
              gender: _gender,
              city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Akun Anda siap digunakan.')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSso() async {
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final emailCtrl = TextEditingController(text: 'pasien.baru.gso@gmail.com');
        final nameCtrl = TextEditingController(text: 'Pasien Baru NDC');
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daftar via Google SSO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Gunakan Akun Gmail untuk Pendaftaran Cepat', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Email Gmail Google Anda:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  hintText: 'nama.anda@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Nama Lengkap Google:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (emailCtrl.text.trim().isNotEmpty) {
                      Navigator.pop(ctx, {
                        'email': emailCtrl.text.trim(),
                        'name': nameCtrl.text.trim().isEmpty ? 'Pengguna Google' : nameCtrl.text.trim()
                      });
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  child: const Text('Lanjutkan & Lengkapi Profil'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected['email'] == null || selected['email']!.isEmpty) return;

    final email = selected['email']!;
    final name = selected['name'] ?? 'Pengguna Google';

    if (mounted) {
      context.push('/complete-profile?email=${Uri.encodeComponent(email)}&name=${Uri.encodeComponent(name)}');
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
        title: const Text('Daftar Akun Pasien Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('DAFTAR DENGAN GMAIL SSO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSso,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.blue.shade200),
                      backgroundColor: Colors.blue.shade50.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Daftar dengan Google (Gmail SSO)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ATAU DAFTAR MANUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Buat Akun NDC Baru ✨',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Silakan isi formulir di bawah ini untuk mendaftarkan akun pasien.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Text('Nama Lengkap Pasien *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(hintText: 'Contoh: Budi Santoso'),
                  validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                const Text('Email (Opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'budi@example.com'),
                ),
                const SizedBox(height: 20),
                const Text('Nomor Whatsapp (Aktif) *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '081234567890',
                    errorText: _phoneValid ? null : 'Nomor WhatsApp wajib diisi',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Nomor WhatsApp tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                const Text('Jenis Kelamin *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Laki-Laki'),
                        value: 'male',
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Perempuan'),
                        value: 'female',
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Tanggal Lahir (Opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      hintText: 'Pilih Tanggal Lahir',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dob != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(_dob!) : 'Pilih Tanggal Lahir (opsional)',
                      style: TextStyle(color: _dob != null ? AppColors.textDark : AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Kota Tempat Tinggal (Opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(hintText: 'Contoh: Bandung'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Punya Kode Referal? ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '(Dapatkan 50 Poin Bonus)',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _referralCtrl,
                  decoration: const InputDecoration(hintText: 'Kode Referal'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Daftar Sekarang'),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah Punya Akun? ', style: TextStyle(fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: const Text(
                          'Yuk Login',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Dengan masuk, kamu menyetujui syarat & ketentuan berlaku',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
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

