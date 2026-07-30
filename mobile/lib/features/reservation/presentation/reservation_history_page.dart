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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDateTime(reservation.scheduledAt), style: const TextStyle(fontWeight: FontWeight.w700)),
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
          ],
        ),
      ),
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
