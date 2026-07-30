import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = [
      (
        title: 'Pengingat Jadwal Reservasi Klinik',
        body: 'Jadwal konsultasi Anda besok pukul 20:30 WIB di Nina Dental Care Soreang.',
        time: '1 jam yang lalu',
        unread: true,
        icon: Icons.calendar_today,
      ),
      (
        title: 'Promo Spesial Grand Opening',
        body: 'Dapatkan diskon 50% untuk Scaling Gigi minggu ini. Klaim voucher di menu Promo!',
        time: 'Kemarin',
        unread: true,
        icon: Icons.local_offer,
      ),
      (
        title: 'Status Rekam Medis Diperbarui',
        body: 'Dokter telah menambahkan rekam medis dan resep tindakan terbaru.',
        time: '3 hari yang lalu',
        unread: false,
        icon: Icons.medical_services,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Notifikasi Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = notifications[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.unread ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(item.icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                          ),
                          Text(item.time, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.body, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
