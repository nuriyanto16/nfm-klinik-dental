import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ConnectMedicalRecordSheet extends StatefulWidget {
  const ConnectMedicalRecordSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ConnectMedicalRecordSheet(),
    );
  }

  @override
  State<ConnectMedicalRecordSheet> createState() => _ConnectMedicalRecordSheetState();
}

class _ConnectMedicalRecordSheetState extends State<ConnectMedicalRecordSheet> {
  final _rmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _rmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rmCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nomor RM "${_rmCtrl.text.trim()}" berhasil terhubung ke akun Anda!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hubungkan Rekam Medis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan Nomor Rekam Medis (RM) yang tercantum pada kartu pasien atau struk transaksi Anda di klinik Nina Dental Care.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text('Nomor Rekam Medis (RM)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _rmCtrl,
              decoration: const InputDecoration(
                hintText: 'Contoh: RM-0001 / 100234',
                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Hubungkan Akun'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
