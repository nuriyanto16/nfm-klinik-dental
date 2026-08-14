import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../data/reservation_model.dart';
import '../data/reservation_repository.dart';

class ReservationDetailPage extends ConsumerWidget {
  const ReservationDetailPage({
    super.key,
    required this.reservationId,
    this.reservation,
  });

  final String reservationId;
  final Reservation? reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reservation != null) {
      return _buildContent(context, reservation!);
    }

    final detailAsync = ref.watch(reservationDetailProvider(reservationId));

    return detailAsync.when(
      data: (fetched) {
        final res = fetched ??
            Reservation(
              id: reservationId,
              patientId: 'patient-1',
              branchId: 'branch-1',
              staffId: 'staff-1',
              scheduledAt: DateTime.now().add(const Duration(days: 2)),
              status: 'confirmed',
              patientName: 'Nuriyanto',
              branchName: 'Nina Dental Care - Soreang',
              doctorName: 'drg. Nina Marlina, Sp.KG',
              treatments: 'Scaling 6-in-1 Super Clean & Konsultasi Gigi',
              complaintNote: 'Pemeriksaan rutin dan pembersihan karang gigi',
            );
        return _buildContent(context, res);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Detail Reservasi'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildContent(
        context,
        Reservation(
          id: reservationId,
          patientId: 'patient-1',
          branchId: 'branch-1',
          staffId: 'staff-1',
          scheduledAt: DateTime.now().add(const Duration(days: 2)),
          status: 'confirmed',
          patientName: 'Nuriyanto',
          branchName: 'Nina Dental Care - Soreang',
          doctorName: 'drg. Nina Marlina, Sp.KG',
          treatments: 'Scaling 6-in-1 Super Clean & Konsultasi Gigi',
          complaintNote: 'Pemeriksaan rutin dan pembersihan karang gigi',
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Reservation res) {

    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(res.scheduledAt);
    final formattedTime = DateFormat('HH:mm', 'id_ID').format(res.scheduledAt);
    final statusColor = _getStatusColor(res.status);
    final statusLabel = reservationStatusLabel(res.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detail Reservasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textMuted),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Tiket Reservasi NDC: ${res.queueTicketNumber} (Dokter: ${res.doctorName}, Jadwal: $formattedDate $formattedTime WIB)'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Info tiket reservasi disalin ke clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Pass Header Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Status Header Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.confirmation_number_rounded, color: statusColor, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'TIKET ANTRIAN KLINIK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Big Ticket Number & Barcode Representation
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withValues(alpha: 0.05), const Color(0xFF0284C7).withValues(alpha: 0.08)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Nomor Tiket Antrian',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  res.queueTicketNumber,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Simulated Barcode Lines
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    32,
                                    (i) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      width: (i % 3 == 0) ? 3 : 1.5,
                                      height: 36,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ID: ${res.id}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Doctor Info
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.doctorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Dokter Spesialis Konservasi Gigi',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 28, color: Color(0xFFEDF2F7)),

                          // Clinic Branch Info
                          _buildDetailTile(
                            icon: Icons.storefront_rounded,
                            iconColor: AppColors.pink,
                            title: 'Cabang Klinik',
                            value: res.branchName,
                            subtitle: 'Jl. Raya Soreang No. 12, Kab. Bandung',
                          ),

                          const SizedBox(height: 14),

                          // Date & Time Info
                          _buildDetailTile(
                            icon: Icons.event_available_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: 'Waktu Periksa',
                            value: formattedDate,
                            subtitle: 'Jam $formattedTime WIB',
                          ),

                          const SizedBox(height: 14),

                          // Patient Name
                          _buildDetailTile(
                            icon: Icons.person_rounded,
                            iconColor: Colors.purple,
                            title: 'Nama Pasien',
                            value: res.patientName,
                            subtitle: 'Pasien Terdaftar NDC',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Treatment Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cleaning_services_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Layanan & Keluhan',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Perawatan Gigi:', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            res.treatments.isNotEmpty ? res.treatments : 'Konsultasi & Pemeriksaan Gigi',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          if (res.complaintNote != null && res.complaintNote!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text('Catatan / Keluhan:', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              res.complaintNote!,
                              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    context.push('/payment/checkout?reservationId=${res.id}&amount=199000');
                  },
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: const Text(
                    'Bayar Sekarang',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungi Customer Service WhatsApp Nina Dental Care (+62811234501)...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_outlined, color: AppColors.primary, size: 20),
                  label: const Text(
                    'Bantuan / Hubungi Klinik via WA',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'terkonfirmasi':
        return Colors.green.shade600;
      case 'pending':
        return Colors.orange.shade700;
      case 'completed':
      case 'selesai':
        return const Color(0xFF0284C7);
      case 'cancelled':
      case 'dibatalkan':
        return Colors.red.shade600;
      default:
        return AppColors.primary;
    }
  }
}
