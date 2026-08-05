import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/content_repository.dart';
import '../data/used_vouchers_provider.dart';

class PromosPage extends ConsumerWidget {
  const PromosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(promoListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text(
          'Promo & Voucher Spesial',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
              final code = promo.voucherCode ?? 'PROMO${i + 1}';

              return Consumer(
                builder: (context, ref, _) {
                  final usedVouchers = ref.watch(usedVouchersProvider);
                  final isUsed = usedVouchers.contains(code.toUpperCase());

                  return Container(
                    decoration: BoxDecoration(
                      color: isUsed ? const Color(0xFFF1F5F9) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isUsed ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        if (!isUsed)
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
                          child: SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: promo.bannerImageUrl != null
                                ? CachedNetworkImage(imageUrl: promo.bannerImageUrl!, fit: BoxFit.cover)
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isUsed
                                            ? [const Color(0xFF64748B), const Color(0xFF475569)]
                                            : [const Color(0xFF0284C7), const Color(0xFF2563EB)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isUsed ? Colors.grey.shade400 : Colors.amber,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isUsed ? 'VOUCHER TERPAKAI' : 'PROMO SPESIAL',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      promo.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isUsed ? AppColors.textMuted : AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  if (promo.discountValue != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isUsed ? Colors.grey.shade200 : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        promo.discountType == 'percentage'
                                            ? 'Hemat ${promo.discountValue!.toInt()}%'
                                            : 'Hemat Rp ${(promo.discountValue! / 1000).toInt()}k',
                                        style: TextStyle(
                                          color: isUsed ? Colors.grey.shade600 : const Color(0xFF166534),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              if (promo.description != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  promo.description!,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ],

                              const SizedBox(height: 14),

                              // Voucher Code Box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isUsed ? Colors.grey.shade100 : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isUsed ? Colors.grey.shade300 : const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.confirmation_number_outlined, size: 18, color: isUsed ? Colors.grey : AppColors.pink),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('KODE VOUCHER', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                            Text(
                                              code,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: isUsed ? Colors.grey.shade600 : AppColors.textDark,
                                                decoration: isUsed ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (isUsed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('Sudah Digunakan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                                      )
                                    else
                                      TextButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: code));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Kode Voucher "$code" berhasil disalin!'),
                                              backgroundColor: AppColors.pink,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.pink),
                                        label: const Text('Salin Kode', style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isUsed ? Colors.grey.shade400 : AppColors.pink,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: isUsed
                                      ? null
                                      : () {
                                          context.push('/reservations/new');
                                        },
                                  child: Text(
                                    isUsed ? 'Voucher Sudah Digunakan' : 'Gunakan Voucher & Reservasi',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
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
