import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/session_storage.dart';
import '../../../core/widgets/section_header.dart';
import '../../content/data/content_models.dart';
import '../../content/data/content_repository.dart';
import '../../patient/application/session_controller.dart';

class _QuickMenuItem {
  const _QuickMenuItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

const _quickMenu = [
  _QuickMenuItem('Reservasi', Icons.calendar_month_outlined, '/reservations/new'),
  _QuickMenuItem('Daftar Harga', Icons.list_alt_outlined, '/pricelist'),
  _QuickMenuItem('Cabang', Icons.map_outlined, '/branches'),
  _QuickMenuItem('Riwayat Bayar', Icons.receipt_long_outlined, '/payments/history'),
  _QuickMenuItem('Dokter', Icons.medical_services_outlined, '/doctors'),
  _QuickMenuItem('Profil', Icons.person_outline, '/profile'),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).value;
    final promos = ref.watch(promoListProvider);
    final articles = ref.watch(articleListProvider);
    final testimonials = ref.watch(testimonialListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nina Dental Care'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(promoListProvider);
          ref.invalidate(articleListProvider);
          ref.invalidate(testimonialListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _WelcomeCard(session: session),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              children: [
                for (final item in _quickMenu)
                  InkWell(
                    onTap: () => context.push(item.route),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(item.icon, color: colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            promos.when(
              data: (list) => list.isEmpty ? const SizedBox.shrink() : _PromoCarousel(promos: list),
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Artikel & Tips',
              actionLabel: 'Lihat Semua',
              onAction: () => context.push('/articles'),
            ),
            const SizedBox(height: 12),
            articles.when(
              data: (list) => list.isEmpty
                  ? const EmptyState(icon: Icons.article_outlined, message: 'Belum ada artikel.')
                  : SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length > 5 ? 5 : list.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => _ArticleCard(article: list[i]),
                      ),
                    ),
              loading: () => const SizedBox(
                height: 190,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Apa Kata Mereka'),
            const SizedBox(height: 12),
            testimonials.when(
              data: (list) => list.isEmpty
                  ? const EmptyState(icon: Icons.reviews_outlined, message: 'Belum ada testimoni.')
                  : SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => _TestimonialCard(testimonial: list[i]),
                      ),
                    ),
              loading: () => const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Reservasi'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              context.push('/reservations/new');
            case 2:
              context.push('/profile');
          }
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.session});

  final PatientSession? session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session == null ? 'Selamat datang!' : 'Halo, ${session!.fullName.split(' ').first}!',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            session == null
                ? 'Lengkapi profil Anda untuk mulai reservasi di Nina Dental Care.'
                : 'Butuh perawatan gigi? Buat reservasi sekarang.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: colorScheme.primary),
            onPressed: () => context.push(session == null ? '/register' : '/reservations/new'),
            child: Text(session == null ? 'Lengkapi Profil' : 'Buat Reservasi'),
          ),
        ],
      ),
    );
  }
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel({required this.promos});

  final List<Promo> promos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        itemCount: promos.length,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (context, i) {
          final promo = promos[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (promo.bannerImageUrl != null)
                    CachedNetworkImage(imageUrl: promo.bannerImageUrl!, fit: BoxFit.cover)
                  else
                    Container(color: Theme.of(context).colorScheme.secondaryContainer),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Text(
                      promo.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: article.coverImageUrl != null
                    ? CachedNetworkImage(imageUrl: article.coverImageUrl!, fit: BoxFit.cover)
                    : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                  if (article.categoryName != null) ...[
                    const SizedBox(height: 4),
                    Text(article.categoryName!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final Testimonial testimonial;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < testimonial.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  '"${testimonial.quote}"',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                testimonial.patientName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
