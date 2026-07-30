import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/session_controller.dart';
import '../data/patient_repository.dart';

class AddPatientSheet extends ConsumerWidget {
  const AddPatientSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPatientSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambah Data Pasien',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          // Option 1
          _OptionCard(
            title: 'Tambah anggota keluarga baru',
            subtitle: 'Klik disini untuk mendaftarkan pasien baru (anak/pasangan/orang tua) yang belum pernah reservasi sebelumnya.',
            icon: Icons.person_add_alt_1_rounded,
            color: Colors.pink.shade50,
            onTap: () {
              Navigator.pop(context);
              _showAddUnregisteredForm(context, ref);
            },
          ),
          const SizedBox(height: 16),
          // Option 2
          _OptionCard(
            title: 'Hubungkan pasien terdaftar',
            subtitle: 'Menghubungkan akun keluarga yang sudah reservasi sendiri sebelumnya — segera hadir.',
            icon: Icons.qr_code_scanner_rounded,
            color: Colors.green.shade50,
            onTap: () {
              Navigator.pop(context);
              _showComingSoonNotice(context);
            },
          ),
        ],
      ),
    );
  }

  static void _showAddUnregisteredForm(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    var relation = 'child';
    var isSaving = false;
    const relationLabels = {'child': 'Anak', 'spouse': 'Pasangan', 'parent': 'Orang Tua', 'other': 'Lainnya'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Tambah Anggota Keluarga'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap Pasien'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: relation,
                  decoration: const InputDecoration(labelText: 'Hubungan'),
                  items: relationLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => relation = v ?? relation),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final session = ref.read(sessionControllerProvider).value;
                        if (session == null) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Daftar/masuk akun utama terlebih dahulu sebelum menambah anggota keluarga.')),
                          );
                          return;
                        }
                        setState(() => isSaving = true);
                        try {
                          await ref.read(patientRepositoryProvider).createPatient(
                                CreatePatientInput(
                                  fullName: nameCtrl.text.trim(),
                                  relation: relation,
                                  primaryAccountUserId: session.patientId,
                                ),
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${nameCtrl.text} berhasil ditambahkan sebagai ${relationLabels[relation]}.')),
                            );
                          }
                        } catch (e) {
                          setState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menambahkan pasien: $e')),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _showComingSoonNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Segera Hadir'),
        content: const Text(
          'Menghubungkan akun keluarga yang sudah pernah reservasi sendiri sedang dikembangkan. '
          'Untuk saat ini, gunakan "Tambah anggota keluarga baru" agar pasien tersebut langsung terhubung ke akun Anda.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
