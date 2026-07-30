import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../data/content_models.dart';
import '../data/content_repository.dart';

class ArticlesPage extends ConsumerStatefulWidget {
  const ArticlesPage({super.key});

  @override
  ConsumerState<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends ConsumerState<ArticlesPage> {
  String _selectedCategory = 'Semua';

  final _defaultArticles = [
    Article(
      id: 'art-1',
      title: 'Kapan Harus Pakai Behel Gigi? Kenali 5 Tanda Utama Ini!',
      slug: 'kapan-harus-behel',
      coverImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80',
      body: '''Gigi berjejal, gingsul yang mengganggu gigitan, atau rahang yang terasa tidak simetris seringkali menjadi alasan utama seseorang membutuhkan perawatan ortodonti (behel gigi).

Perawatan behel tidak hanya bertujuan estetika untuk mempercantik senyuman, tetapi juga sangat krusial untuk kesehatan artikulasi dan fungsi mengunyah makanan.

Tanda Utama Kamu Membutuhkan Behel:
1. Gigi bertumpuk / berjejal sehingga sulit dibersihkan dengan sikat gigi biasa.
2. Jarak antargigi terlalu lebar (renggang).
3. Underbite atau overbite (gigitan atas/bawah terlalu maju).
4. Sering merasa nyeri pada persendian rahang (TMJ) saat mengunyah.
5. Kesulitan mengucapkan kata-kata tertentu dengan jelas.

Di Nina Dental Care, prosedur pemasangan behel diawali dengan foto Rontgen Panoramik & Cephalometri komprehensif, pencetakan studi rahang, serta konsultasi langsung bersama dokter spesialis ortodonti kami.''',
      categoryName: 'Ortodonti',
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Article(
      id: 'art-2',
      title: '5 Kebiasaan Sehari-hari yang Tanpa Disadari Merusak Enamel Gigi',
      slug: '5-kebiasaan-perusak-enamel',
      coverImageUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80',
      body: '''Enamel gigi adalah lapisan terluar dan terkeras pada tubuh manusia yang melindungi mahkota gigi. Meskipun sangat kuat, enamel bisa terkikis akibat kebiasaan asam dan mekanis sehari-hari.

Kebiasaan Merusak Enamel:
1. Menyikat gigi terlalu keras dengan bulu sikat yang kasar.
2. Mengonsumsi minuman bersoda, boba, atau jus sitrus berlebihan tanpa membilas air putih.
3. Menggigit es batu atau membuka kemasan plastik menggunakan gigi.
4. Kebiasaan menggeretakkan gigi (bruxism) saat tidur malam.
5. Langsung menyikat gigi kurang dari 30 menit setelah makan makanan asam.

Tips Pencegahan:
Gunakan sikat gigi berbulu halus (soft / ultra-soft), aplikasikan pasta gigi ber-fluoride tinggi, dan lakukan pemeriksaan rutin 6 bulan sekali di klinik Nina Dental Care.''',
      categoryName: 'Tips Kesehatan',
      publishedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Article(
      id: 'art-3',
      title: 'Program Nina Kidz: Menjaga Gigi Anak Sehat & Bebas Karies Sejak Dini',
      slug: 'program-nina-kidz',
      coverImageUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800&auto=format&fit=crop&q=80',
      body: '''Menjaga kesehatan gigi susu anak sama pentingnya dengan gigi permanen. Gigi susu berfungsi sebagai penuntun arah tumbuh gigi permanen kelak.

Mengapa Nina Kidz Sangat Disukai Anak & Orang Tua?
- Ruang pemeriksaan bernuansa edukatif dan menyenangkan.
- Dokter gigi spesialis kedokteran gigi anak (Sp.KGA) yang ramah & sabar.
- Penanganan Topical Fluoride Treatment & Pit Fissure Sealant untuk melapisi parit gigi dari sisa sisa susu/makanan.

Dapatkan pemeriksaan gratis dental kit spesial untuk kunjungan pertama si kecil di cabang Soreang dan Baleendah!''',
      categoryName: 'Nina Kidz',
      publishedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Article(
      id: 'art-4',
      title: 'Prosedur Bleaching Gigi Instant: Rahasia Senyum Cerah Cemerlang',
      slug: 'prosedur-bleaching-gigi',
      coverImageUrl: 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80',
      body: '''Warna gigi dapat menguning akibat konsumsi kopi, teh, rokok, atau faktor usia. Bleaching (In-Office Whitening) adalah solusi tercepat untuk mencerahkan warna gigi hingga 4-8 tingkat lebih putih hanya dalam waktu 60 menit.

Keunggulan Bleaching di Nina Dental Care:
- Menggunakan bahan whitening berstandar internasional yang aman untuk enamel.
- Dilengkapi perlindungan gusi (gingival barrier) sehingga tidak menimbulkan rasa ngilu berlebih.
- Hasil langsung terlihat instan dalam satu kali sesi kunjungan!''',
      categoryName: 'Perawatan Gigi',
      publishedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articleListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: const Text(
          'Edukasi & Artikel Gigi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(articleListProvider.future),
        child: articlesAsync.when(
          data: (apiArticles) {
            final articles = apiArticles.isNotEmpty ? apiArticles : _defaultArticles;
            final categories = ['Semua', 'Ortodonti', 'Tips Kesehatan', 'Perawatan Gigi', 'Nina Kidz'];

            final filtered = _selectedCategory == 'Semua'
                ? articles
                : articles.where((a) => a.categoryName == _selectedCategory).toList();

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Horizontal Category Chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.pink,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppColors.pink : const Color(0xFFE2E8F0),
                          ),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Featured Main Article Header Card if 'Semua' selected
                if (_selectedCategory == 'Semua' && articles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeaturedArticleCard(context, articles.first),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Artikel Terbaru',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Articles List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (final article in (_selectedCategory == 'Semua' && filtered.length > 1 ? filtered.sublist(1) : filtered)) ...[
                        _buildArticleCard(context, article),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildFeaturedArticleCard(BuildContext context, Article article) {
    return GestureDetector(
      onTap: () => context.push('/articles/${article.id}', extra: article),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: article.coverImageUrl != null
                    ? CachedNetworkImage(imageUrl: article.coverImageUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.pink.shade100, child: const Icon(Icons.article, size: 48, color: AppColors.pink)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.categoryName ?? 'Artikel',
                          style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      const Text('4 mnt baca', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article) {
    return GestureDetector(
      onTap: () => context.push('/articles/${article.id}', extra: article),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: article.coverImageUrl != null
                    ? CachedNetworkImage(imageUrl: article.coverImageUrl!, fit: BoxFit.cover)
                    : Container(color: Colors.green.shade50, child: const Icon(Icons.article, color: AppColors.primary)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.categoryName ?? 'Artikel',
                      style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        article.publishedAt != null ? formatDate(article.publishedAt!) : 'Terbaru',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
