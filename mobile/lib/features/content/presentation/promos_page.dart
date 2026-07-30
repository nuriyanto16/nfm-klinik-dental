import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/content_repository.dart';

class PromosPage extends ConsumerWidget {
  const PromosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(promoListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Promo Spesial Nina Dental Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: promosAsync.when(
        data: (promos) {
          if (promos.isEmpty) {
            return const Center(child: Text('Belum ada promo aktif saat ini.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: promos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final promo = promos[i];
              return Container(
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
                    // Banner Box
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFEC407A), Color(0xFFAB47BC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: promo.bannerImageUrl != null
                            ? CachedNetworkImage(imageUrl: promo.bannerImageUrl!, fit: BoxFit.cover)
                            : Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('PROMO SPESIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      promo.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                          ),
                          if (promo.description != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              promo.description!,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.pink,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                context.push('/reservations/new');
                              },
                              child: const Text('Gunakan Promo & Reservasi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => SkeletonList(
          itemBuilder: (_, _) => const SkeletonBanner(),
          itemCount: 3,
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
