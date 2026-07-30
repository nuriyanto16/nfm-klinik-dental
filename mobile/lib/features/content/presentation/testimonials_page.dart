import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/content_repository.dart';

class TestimonialsPage extends ConsumerWidget {
  const TestimonialsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonialsAsync = ref.watch(testimonialListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Testimoni Pasien', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: testimonialsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada testimoni pasien.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final t = list[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFE2E8F0),
                          child: Icon(Icons.person, color: AppColors.textMuted, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                              ),
                              const Text('Pasien Nina Dental Care', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (idx) => Icon(
                              idx < t.rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '"${t.quote}"',
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textDark, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.medical_services_outlined, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Dokter penanggung jawab: drg. Friski Raisis',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => SkeletonList(
          itemBuilder: (_, _) => const SkeletonDoctorCard(),
          itemCount: 4,
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
