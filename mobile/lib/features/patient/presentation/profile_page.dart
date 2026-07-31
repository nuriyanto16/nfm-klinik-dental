import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../application/session_controller.dart';
import 'add_patient_sheet.dart';
import 'connect_medical_record_sheet.dart';

import 'edit_profile_sheet.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).value;

    final fullName = session?.fullName ?? 'Nuriyanto';
    final phone = session?.phoneWa ?? '087823339007';
    const email = 'sayarhungs@gmail.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Profilku', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
            onPressed: () {
              _showLogoutDialog(context, ref);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Text(
              fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const Text(email, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 20),
            // Membership Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFEDF2F7),
                    child: Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Silver Membership',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/membership'),
                    child: const Text(
                      'Lihat Detail',
                      style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons (Edit & Hubungkan Rekam Medis)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E0)),
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => EditProfileSheet.show(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E0)),
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => ConnectMedicalRecordSheet.show(context),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Hubungkan Rekam Medis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Transformasi Behel & Senyum Real Human Photos Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.pink, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Progres Transformasi Senyumku',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80',
                                height: 70,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Bln 0 (Awal)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80',
                                height: 70,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Bln 6 (Behel)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80',
                                height: 70,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('Bln 14 (Rapi)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info List
            _buildProfileInfoItem('Tanggal Lahir', '16 November 1990'),
            _buildProfileInfoItem('Tempat Lahir', '-'),
            _buildProfileInfoItem('Jenis Kelamin', 'Pria'),
            _buildProfileInfoItem('Alamat', 'Jalan Belum Diisi'),
            const SizedBox(height: 16),
            // Quick Links: Asuransi & Tambah Pasien
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
              title: const Text('Data Asuransi', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/insurance'),
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom, color: AppColors.primary),
              title: const Text('Tambah Data Pasien / Keluarga', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AddPatientSheet.show(context),
            ),
            const SizedBox(height: 24),
            // Patient QR Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.pink, width: 1.5),
                ),
                onPressed: () => context.push('/qr-profile'),
                icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.pink),
                label: const Text(
                  'Patient QR',
                  style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(sessionControllerProvider.notifier).logout();
              if (context.mounted) context.go('/home');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
