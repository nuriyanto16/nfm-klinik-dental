import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/session_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../content/data/content_models.dart';
import '../../content/data/content_repository.dart';
import '../../content/presentation/dicy_chat_sheet.dart';
import '../../patient/application/session_controller.dart';
import '../../patient/presentation/add_patient_sheet.dart';

class _QuickMenuItem {
  const _QuickMenuItem(this.label, this.icon, this.route, {this.badge});
  final String label;
  final IconData icon;
  final String route;
  final String? badge;
}

const _quickMenu = [
  _QuickMenuItem('Promo', Icons.local_offer_outlined, '/promos', badge: '🔥'),
  _QuickMenuItem('Reservasi', Icons.calendar_today_outlined, '/reservations/new'),
  _QuickMenuItem('Pricelist', Icons.receipt_long_outlined, '/pricelist'),
  _QuickMenuItem('Klinik Terdekat', Icons.home_outlined, '/branches'),
  _QuickMenuItem('Payment History', Icons.credit_card_outlined, '/payments/history'),
  _QuickMenuItem('Dokter', Icons.medical_services_outlined, '/doctors'),
  _QuickMenuItem('Info Asuransi', Icons.shield_outlined, '/insurance'),
  _QuickMenuItem('Tampilkan Semua', Icons.keyboard_arrow_down_rounded, '/pricelist'),
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentPromoPage = 0;
  String _selectedArticleCategory = 'Semua';
  bool _showDicyBubble = true;
  late PageController _promoPageController;

  final List<String> _articleCategories = [
    'Semua',
    'Behel Gigi',
    'Bleaching',
    'Cabut Gigi',
    'Event',
  ];

  @override
  void initState() {
    super.initState();
    _promoPageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final promos = ref.read(promoListProvider);
      promos.whenData((list) {
        if (list.isEmpty) return;
        final next = (_currentPromoPage + 1) % list.length;
        if (_promoPageController.hasClients) {
          _promoPageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
        _startAutoScroll();
      });
    });
  }

  @override
  void dispose() {
    _promoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).value;
    final promos = ref.watch(promoListProvider);
    final articles = ref.watch(articleListProvider);
    final testimonials = ref.watch(testimonialListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ndc',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Nina Dental Care',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(promoListProvider);
              ref.invalidate(articleListProvider);
              ref.invalidate(testimonialListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                // Top Header Curve & Auth Banner
                _buildTopAuthBanner(context, session),
                const SizedBox(height: 16),

                // Promo Carousel with Dots & Auto-scroll
                promos.when(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            SizedBox(
                              height: 195,
                              child: PageView.builder(
                                itemCount: list.length,
                                controller: _promoPageController,
                                onPageChanged: (i) => setState(() => _currentPromoPage = i),
                                itemBuilder: (context, i) => _buildPromoCard(list[i]),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                list.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentPromoPage == i ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentPromoPage == i ? AppColors.pink : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  loading: () => const SkeletonBanner(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // 8 Quick Access Icons Grid
                GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                  ),
                  shrinkWrap: true,
                  itemCount: _quickMenu.length,
                  itemBuilder: (context, i) {
                    final item = _quickMenu[i];
                    return InkWell(
                      onTap: () {
                        if (item.label == 'Tampilkan Semua') {
                          _showAllMenuSheet(context);
                        } else {
                          context.push(item.route);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: i % 2 == 0 ? Colors.green.shade50 : Colors.pink.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: i % 2 == 0 ? AppColors.primary : AppColors.pink, size: 26),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.badge != null) Text(item.badge!, style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // MY REWARD Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'MY REWARD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          onPressed: () => context.push('/reward'),
                          child: const Text('AMBIL', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Testimoni Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Testimoni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      GestureDetector(
                        onTap: () => context.push('/testimonials'),
                        child: const Text('Lihat Semua', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                testimonials.when(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (context, i) => _buildTestimonialCard(list[i]),
                          ),
                        ),
                  loading: () => const SkeletonHorizontalList(itemWidth: 260, itemHeight: 140),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 28),

                // Video Edukasi Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Video Edukasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      GestureDetector(
                        onTap: () => context.push('/videos'),
                        child: const Text('Lihat Semua', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 3,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => _buildEducationalVideoCard(i),
                  ),
                ),

                const SizedBox(height: 28),

                // Artikel Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Artikel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      GestureDetector(
                        onTap: () => context.push('/articles'),
                        child: const Text('Lihat Semua', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips for articles
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _articleCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _articleCategories[i];
                      final isSelected = cat == _selectedArticleCategory;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.pink,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedArticleCategory = cat);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                articles.when(
                  data: (list) {
                    final filtered = _selectedArticleCategory == 'Semua'
                        ? list
                        : list.where((a) => (a.categoryName ?? '').toLowerCase().contains(_selectedArticleCategory.toLowerCase())).toList();

                    if (filtered.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Belum ada artikel di kategori ini.'),
                      );
                    }

                    return SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => _buildArticleCard(context, filtered[i]),
                      ),
                    );
                  },
                  loading: () => const SkeletonHorizontalList(itemWidth: 220, itemHeight: 210),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Floating Dicy Assistant Chat Widget at bottom right
          if (_showDicyBubble)
            Positioned(
              right: 16,
              bottom: 80,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showDicyBubble = false),
                          child: const Icon(Icons.close, size: 14, color: Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Halo, ada yang bisa Dicy bantu?',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => DicyChatSheet.show(context),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.pink,
                      child: Icon(Icons.question_answer_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Reservation'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Pricelist'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/schedule');
            case 2:
              context.push('/reservations/new');
            case 3:
              context.push('/pricelist');
            case 4:
              context.push('/profile');
          }
        },
      ),
    );
  }

  Widget _buildTopAuthBanner(BuildContext context, PatientSession? session) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: session == null
          ? Column(
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jadilah member kami dan dapatkan keuntungannya !',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pink,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.push('/login'),
                        child: const Text('Login'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        onPressed: () => context.push('/register'),
                        child: const Text('Register'),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Row(
                          children: [
                            Icon(Icons.error, color: Colors.yellowAccent, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'No RM: Belum terhubung.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text('Silver Member', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pink,
                        ),
                        onPressed: () => AddPatientSheet.show(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Pasien', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        onPressed: () => context.push('/qr-profile'),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('My QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPromoCard(Promo promo) {
    final bannerUrl = (promo.bannerImageUrl != null && promo.bannerImageUrl!.isNotEmpty)
        ? promo.bannerImageUrl!
        : 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => context.push('/promos'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: bannerUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Dark gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.78),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Content overlay
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_offer_rounded, size: 11, color: Colors.black87),
                              SizedBox(width: 4),
                              Text('PROMO SPESIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Detail →', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      promo.title,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, height: 1.2, shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo.description ?? 'Konsultasi dokter gratis & diskon khusus reservasi via aplikasi mobile!',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(Testimonial t) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
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
              width: 60,
              height: 70,
              child: CachedNetworkImage(
                imageUrl: t.photoUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.pink.shade50,
                  child: const Icon(Icons.person, size: 36, color: AppColors.pink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"${t.quote}"',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < t.rating ? Icons.star : Icons.star_border,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(t.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Text('Dokter yang melayani: drg Friski Raisis', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalVideoCard(int index) {
    final videoTitles = [
      'SERU ABISSS GRAND OPENING NINA DENTAL CARE!',
      'Edukasi: Cara Sikat Gigi yang Benar Mencegah Karang Gigi',
      'Tips Memilih Behel Metal vs Behel Transparan Sapphire'
    ];
    final videoImages = [
      'https://images.unsplash.com/photo-1629909615184-74f495363b67?w=800',
      'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800',
      'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800'
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: videoImages[index % videoImages.length],
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.teal.shade800),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.2)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            const Center(
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white70,
                child: Icon(Icons.play_arrow, color: AppColors.primary, size: 28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('#EVENT & EDUKASI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoTitles[index % videoTitles.length],
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text('NINA DENTAL CARE OFFICIAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.amber)),
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

  Widget _buildArticleCard(BuildContext context, Article article) {
    final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(article.publishedAt ?? DateTime.now());
    final coverUrl = (article.coverImageUrl != null && article.coverImageUrl!.isNotEmpty)
        ? article.coverImageUrl!
        : 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80';

    final categoryColors = <String, List<Color>>{
      'Ortodonti': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      'Tips Kesehatan': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      'Nina Kidz': [const Color(0xFFF7971E), const Color(0xFFFFD200)],
      'Perawatan Gigi': [const Color(0xFFFC5C7D), const Color(0xFF6A3093)],
      'Bleaching': [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
    };
    final catName = article.categoryName ?? 'Artikel';
    final gradColors = categoryColors[catName] ?? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];

    return GestureDetector(
      onTap: () => context.push('/articles/${article.id}'),
      child: SizedBox(
        width: 225,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Cover image
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      // Bottom fade
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradColors),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            catName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        const Spacer(),
                        Text(formattedDate, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 12, color: gradColors[0]),
                        const SizedBox(width: 4),
                        Text('Baca Selengkapnya', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: gradColors[0])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllMenuSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final allItems = [
          const _QuickMenuItem('Promo Spesial', Icons.local_offer_outlined, '/promos', badge: '🔥'),
          const _QuickMenuItem('Reservasi Baru', Icons.calendar_today_outlined, '/reservations/new'),
          const _QuickMenuItem('Pricelist & Perawatan', Icons.receipt_long_outlined, '/pricelist'),
          const _QuickMenuItem('Klinik Terdekat', Icons.home_outlined, '/branches'),
          const _QuickMenuItem('Payment History', Icons.credit_card_outlined, '/payments/history'),
          const _QuickMenuItem('Dokter Spesialis', Icons.medical_services_outlined, '/doctors'),
          const _QuickMenuItem('Info Asuransi', Icons.shield_outlined, '/insurance'),
          const _QuickMenuItem('Riwayat Jadwal', Icons.event_available_outlined, '/schedule'),
          const _QuickMenuItem('Membership', Icons.card_membership_outlined, '/membership'),
          const _QuickMenuItem('Hadiah Reward', Icons.card_giftcard_outlined, '/reward'),
          const _QuickMenuItem('Video Edukasi', Icons.play_circle_outline, '/videos'),
          const _QuickMenuItem('Testimoni Pasien', Icons.star_outline, '/testimonials'),
        ];

        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Semua Layanan Klinik',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: allItems.length,
                  itemBuilder: (context, i) {
                    final item = allItems[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.push(item.route);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: i % 2 == 0 ? Colors.green.shade50 : Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(item.icon, color: i % 2 == 0 ? AppColors.primary : AppColors.pink, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
