import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../application/session_controller.dart';
import '../data/patient_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  String _gender = 'female';
  DateTime? _dateOfBirth;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _onSubmit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Nama lengkap wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).register(
            CreatePatientInput(
              fullName: _nameController.text.trim(),
              relation: 'self',
              gender: _gender,
              dateOfBirth: _dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!) : null,
              email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
              phoneWa: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
              city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
            ),
          );
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      }
    } catch (err) {
      setState(() => _error = apiErrorMessage(err));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Buat profil pasien untuk mulai reservasi dan melihat riwayat kunjungan Anda.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  value: 'female',
                  groupValue: _gender,
                  title: const Text('Perempuan'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: 'male',
                  groupValue: _gender,
                  title: const Text('Laki-laki'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Tanggal Lahir', prefixIcon: Icon(Icons.cake_outlined)),
              child: Text(_dateOfBirth != null ? DateFormat('d MMMM yyyy', 'id_ID').format(_dateOfBirth!) : 'Pilih tanggal'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Nomor WhatsApp', prefixIcon: Icon(Icons.chat_outlined)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email (opsional)', prefixIcon: Icon(Icons.mail_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Kota', prefixIcon: Icon(Icons.location_city_outlined)),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: _loading ? null : _onSubmit,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Buat Profil'),
          ),
        ],
      ),
    );
  }
}
