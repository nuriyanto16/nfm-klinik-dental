import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../data/content_models.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text('Detail Edukasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan artikel disalin ke papan klip!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (article.coverImageUrl != null)
              CachedNetworkImage(
                imageUrl: article.coverImageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.pink.shade50,
                child: const Icon(Icons.medical_services_outlined, size: 64, color: AppColors.pink),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Reading Time Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          article.categoryName ?? 'Edukasi Gigi',
                          style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      const Text('3 mnt baca', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Article Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Doctor Author Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.pink,
                          child: Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ditinjau oleh drg. Friski Raisis',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                              Text(
                                article.publishedAt != null ? 'Diterbitkan ${formatDate(article.publishedAt!)}' : 'Dokter Spesialis Nina Dental',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Body Content
                  Text(
                    article.body,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bottom Consultation Callout Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Punya Pertanyaan Mengenai Kesehatan Gigimu?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Konsultasikan langsung dengan dokter spesialis Nina Dental Care Soreang & Baleendah.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => context.push('/reservations/new'),
                            child: const Text('Buat Janji Konsultasi Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
