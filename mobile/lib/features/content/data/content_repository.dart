import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'content_models.dart';

final List<Article> _fallbackArticles = [
  Article(
    id: 'art-1',
    categoryName: 'Ortodonti',
    title: 'Kapan Harus Behel Gigi? Kenali 5 Tanda Utama Ini!',
    slug: 'kapan-harus-behel',
    coverImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800',
    body: 'Gigi berjejal, gigitan tidak rata, atau rahang tidak simetris...',
    publishedAt: DateTime.now(),
  ),
  Article(
    id: 'art-2',
    categoryName: 'Tips Kesehatan',
    title: '5 Kebiasaan Sehari-hari yang Tanpa Disadari Merusak Enamel Gigi',
    slug: '5-kebiasaan-perusak-enamel',
    coverImageUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800',
    body: 'Minum soda berlebihan, menggigit kuku...',
    publishedAt: DateTime.now(),
  ),
  Article(
    id: 'art-3',
    categoryName: 'Nina Kidz',
    title: 'Program Nina Kidz: Menjaga Gigi Anak Sehat & Bebas Karies Sejak Dini',
    slug: 'program-nina-kidz',
    coverImageUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800',
    body: 'Nina Kidz adalah program pemeriksaan gigi anak...',
    publishedAt: DateTime.now(),
  ),
];

final List<Promo> _fallbackPromos = [
  const Promo(
    id: 'pro-1',
    title: 'Promo Scaling 6-in-1 Super Clean',
    bannerImageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800',
    description: 'Paket scaling lengkap pembersihan karang gigi + polishing + fluoridasi hanya Rp149.000.',
    isActive: true,
  ),
  const Promo(
    id: 'pro-2',
    title: 'Diskon Pemasangan Behel Metal 10%',
    bannerImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800',
    description: 'Diskon 10% untuk pemasangan behel metal konvensional via aplikasi.',
    isActive: true,
  ),
];

final List<Testimonial> _fallbackTestimonials = [
  const Testimonial(
    id: 'tes-1',
    patientName: 'Budi Santoso',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    photoUrl: null,
    rating: 5,
    quote: 'Pelayanan ramah, klinik sangat bersih dan dokter komunikatif! Tambal giginya rapi dan gak sakit sama sekali.',
  ),
  const Testimonial(
    id: 'tes-2',
    patientName: 'Siti Aminah',
    doctorName: 'drg. Siti Aminah',
    photoUrl: null,
    rating: 5,
    quote: 'Behel anak saya ditangani dengan sabar, dokter anak di Nina Kidz sangat ramah.',
  ),
];

class ContentRepository {
  ContentRepository(this._dio);

  final Dio _dio;

  Future<List<Article>> listArticles() async {
    try {
      final res = await _dio.get<List<dynamic>>('/content/articles');
      final list = (res.data ?? [])
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .where((a) => a.publishedAt != null)
          .toList();
      return list.isNotEmpty ? list : _fallbackArticles;
    } catch (_) {
      return _fallbackArticles;
    }
  }

  Future<List<Promo>> listPromos() async {
    try {
      final res = await _dio.get<List<dynamic>>('/content/promos');
      final list = (res.data ?? [])
          .map((e) => Promo.fromJson(e as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();
      return list.isNotEmpty ? list : _fallbackPromos;
    } catch (_) {
      return _fallbackPromos;
    }
  }

  Future<List<Testimonial>> listTestimonials() async {
    try {
      final res = await _dio.get<List<dynamic>>('/content/testimonials');
      final list = (res.data ?? []).map((e) => Testimonial.fromJson(e as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _fallbackTestimonials;
    } catch (_) {
      return _fallbackTestimonials;
    }
  }
}

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(dioProvider));
});

final articleListProvider = FutureProvider.autoDispose<List<Article>>((ref) {
  return ref.watch(contentRepositoryProvider).listArticles();
});

final promoListProvider = FutureProvider.autoDispose<List<Promo>>((ref) {
  return ref.watch(contentRepositoryProvider).listPromos();
});

final testimonialListProvider = FutureProvider.autoDispose<List<Testimonial>>((ref) {
  return ref.watch(contentRepositoryProvider).listTestimonials();
});
