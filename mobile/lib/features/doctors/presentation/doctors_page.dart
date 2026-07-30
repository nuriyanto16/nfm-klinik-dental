import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../data/doctor_model.dart';
import '../data/doctor_repository.dart';

class DoctorsPage extends ConsumerWidget {
  const DoctorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(doctorListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dokter Kami')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(doctorListProvider.future),
        child: AsyncValueView<List<Doctor>>(
          value: doctors,
          onRetry: () => ref.invalidate(doctorListProvider),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(icon: Icons.medical_services_outlined, message: 'Belum ada data dokter.');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _DoctorTile(doctor: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => context.push('/doctors/${doctor.id}'),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: colorScheme.primaryContainer,
          foregroundImage: doctor.photoUrl != null ? CachedNetworkImageProvider(doctor.photoUrl!) : null,
          child: doctor.photoUrl == null
              ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
              : null,
        ),
        title: Text(doctor.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(doctor.specialization ?? 'Dokter Gigi Umum'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
