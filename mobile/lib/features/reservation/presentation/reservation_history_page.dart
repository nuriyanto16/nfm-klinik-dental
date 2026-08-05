import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../patient/application/session_controller.dart';
import '../data/reservation_model.dart';
import '../data/reservation_repository.dart';

class ReservationHistoryPage extends ConsumerWidget {
  const ReservationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Reservasi')),
      body: session == null
          ? _NoProfileState(onRegister: () => context.push('/register'))
          : Consumer(
              builder: (context, ref, _) {
                final reservations = ref.watch(myReservationsProvider(session.patientId));
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myReservationsProvider(session.patientId).future),
                  child: AsyncValueView<List<Reservation>>(
                    value: reservations,
                    onRetry: () => ref.invalidate(myReservationsProvider(session.patientId)),
                    data: (list) {
                      if (list.isEmpty) {
                        return const EmptyState(icon: Icons.calendar_month_outlined, message: 'Belum ada riwayat reservasi.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _ReservationTile(reservation: list[i]),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation});

  final Reservation reservation;

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Reservasi Pasien',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.3)),
                  ),
                  child: Text(
                    'Tiket: ${reservation.queueTicketNumber}',
                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(icon: Icons.person_outline, label: 'Nama Pasien', value: reservation.patientName ?? 'Pasien NDC'),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.badge_outlined, label: 'Dokter Spesialis', value: reservation.doctorName),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.storefront_outlined, label: 'Cabang Klinik', value: reservation.branchName),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.event_outlined, label: 'Jadwal Periksa', value: formatDateTime(reservation.scheduledAt)),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.cleaning_services_outlined, label: 'Perawatan Gigi', value: reservation.treatments.isNotEmpty ? reservation.treatments : 'Konsultasi & Pemeriksaan Gigi'),
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.check_circle_outline, label: 'Status Antrian', value: reservationStatusLabel(reservation.status)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check),
                label: const Text('Tutup Detail'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatDateTime(reservation.scheduledAt), style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        'Tiket: ${reservation.queueTicketNumber}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(reservationStatusLabel(reservation.status), style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${reservation.doctorName} · ${reservation.branchName}', style: Theme.of(context).textTheme.bodyMedium),
              if (reservation.treatments.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(reservation.treatments, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Lihat Detail', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF0284C7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _NoProfileState extends StatelessWidget {
  const _NoProfileState({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Lengkapi profil untuk melihat riwayat reservasi Anda.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRegister, child: const Text('Lengkapi Profil')),
          ],
        ),
      ),
    );
  }
}
