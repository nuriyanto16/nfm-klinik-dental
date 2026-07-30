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
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir terlebih dahulu.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Lengkapi data dibawah untuk membuat akun.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'sayarhungs@gmail.com'),
                  validator: (v) => v == null || v.isEmpty ? 'E-mail wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(hintText: 'Nuriyanto'),
                  validator: (v) => v == null || v.isEmpty ? 'Nama lengkap wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                const Text('Jenis Kelamin', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Pria', style: TextStyle(fontWeight: FontWeight.w600)),
                        value: 'male',
                        groupValue: _gender,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _gender = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Wanita', style: TextStyle(fontWeight: FontWeight.w600)),
                        value: 'female',
                        groupValue: _gender,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _gender = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Tanggal Lahir', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_month, color: AppColors.textMuted),
                    ),
                    child: Text(
                      _dob == null
                          ? '16 Nov 1990'
                          : DateFormat('dd MMM yyyy', 'id_ID').format(_dob!),
                      style: TextStyle(
                        color: _dob == null ? AppColors.textMuted : AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Kota/Kabupaten', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(hintText: 'Bandung'),
                ),
                const SizedBox(height: 16),
                const Text('Nomor Whatsapp', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) {
                    setState(() => _phoneValid = v.length >= 8);
                  },
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              border: Border.all(color: Colors.white, width: 0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('+62', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    suffixIcon: _phoneValid && _phoneCtrl.text.isNotEmpty
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    hintText: '6287823339007',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
                ),
                if (_phoneValid && _phoneCtrl.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Nomor Whatsapp tersedia!',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Kode Referal ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Opsional', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                        : const Text('Buat Password'),
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
