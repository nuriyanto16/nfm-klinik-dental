import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../branches/data/branch_repository.dart';
import '../data/doctor_model.dart';
import '../data/doctor_repository.dart';

class DoctorDetailPage extends ConsumerWidget {
  const DoctorDetailPage({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctor = ref.watch(doctorDetailProvider(doctorId));
    final branches = ref.watch(branchListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Dokter')),
      body: AsyncValueView<DoctorDetail>(
        value: doctor,
        onRetry: () => ref.invalidate(doctorDetailProvider(doctorId)),
        data: (d) {
          final branchNames = {for (final b in branches.value ?? []) b.id: b.name};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundImage: d.photoUrl != null ? CachedNetworkImageProvider(d.photoUrl!) : null,
                      child: d.photoUrl == null
                          ? Icon(Icons.person, size: 40, color: colorScheme.onPrimaryContainer)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(d.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(d.specialization ?? 'Dokter Gigi Umum', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Jadwal Praktik', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (d.schedules.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Jadwal belum tersedia. Hubungi cabang untuk informasi lebih lanjut.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < d.schedules.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Text(dayNames[d.schedules[i].dayOfWeek].substring(0, 2),
                                style: TextStyle(fontSize: 11, color: colorScheme.onSecondaryContainer)),
                          ),
                          title: Text(dayNames[d.schedules[i].dayOfWeek]),
                          subtitle: Text(branchNames[d.schedules[i].branchId] ?? 'Cabang'),
                          trailing: Text('${d.schedules[i].startTime} – ${d.schedules[i].endTime}'),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/reservations/new?doctorId=${d.id}'),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Reservasi dengan Dokter Ini'),
              ),
            ],
          );
        },
      ),
    );
  }
}
