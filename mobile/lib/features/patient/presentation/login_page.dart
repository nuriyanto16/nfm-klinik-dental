import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../application/session_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(sessionControllerProvider.notifier).login(_emailCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login berhasil! Selamat datang kembali.')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal login: $e')),
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
        final emailCtrl = TextEditingController();
        final nameCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
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
                          Text('Google Sign-In (Gmail SSO)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Pilih Akun Gmail atau Masukkan Email', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text('BS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: const Text('Budi Santoso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('budi.santoso@example.com (Terdaftar)', style: TextStyle(fontSize: 12, color: Colors.green)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.pop(ctx, {'email': 'budi.santoso@example.com', 'name': 'Budi Santoso'}),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.pinkAccent,
                      child: Text('ND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: const Text('Akun Gmail Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('pasien.baru.gso@gmail.com (Belum Terdaftar)', style: TextStyle(fontSize: 12, color: Colors.orange)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.pop(ctx, {'email': 'pasien.baru.gso@gmail.com', 'name': 'Pasien Baru NDC'}),
                  ),
                  const SizedBox(height: 12),
                  const Text('Atau Masukkan Email Gmail Lain:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'nama.anda@gmail.com',
                      isDense: true,
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nama Lengkap Google',
                      isDense: true,
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (emailCtrl.text.trim().isNotEmpty) {
                          Navigator.pop(ctx, {
                            'email': emailCtrl.text.trim(),
                            'name': nameCtrl.text.trim().isEmpty ? 'Pengguna Google' : nameCtrl.text.trim()
                          });
                        }
                      },
                      child: const Text('Lanjutkan SSO Google'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (selected == null || selected['email'] == null || selected['email']!.isEmpty) return;

    final email = selected['email']!;
    final name = selected['name'] ?? 'Pengguna Google';

    setState(() => _isLoading = true);

    try {
      final res = await ref.read(sessionControllerProvider.notifier).handleGoogleSso(
        email: email,
        displayName: name,
      );

      if (!mounted) return;

      if (!res.isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Gmail SSO Berhasil! Selamat datang, ${res.displayName}.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun Gmail belum terdaftar. Silakan lengkapi profil Anda terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
        context.push('/complete-profile?email=${Uri.encodeComponent(email)}&name=${Uri.encodeComponent(name)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal SSO Google: $e')),
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
        title: const Text('Masuk Ke Akun', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang Kembali 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Silakan masukan email/nomor whatsapp dan password Anda.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 32),
                const Text('E-mail / No WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'sayarhungs@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'E-mail tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Password tidak boleh kosong' : null,
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
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ATAU MASUK DENGAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSso,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Masuk dengan Google (Gmail SSO)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? '),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

