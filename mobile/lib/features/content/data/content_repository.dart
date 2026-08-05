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
    coverImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80',
    body: 'Gigi berjejal, gigitan tidak rata, atau rahang tidak simetris bisa jadi tanda kamu butuh behel. Konsultasikan dengan dokter gigi spesialis ortodonti di Nina Dental Care.',
    publishedAt: DateTime.now(),
  ),
  Article(
    id: 'art-2',
    categoryName: 'Tips Kesehatan',
    title: '5 Kebiasaan Sehari-hari yang Tanpa Disadari Merusak Enamel Gigi',
    slug: '5-kebiasaan-perusak-enamel',
    coverImageUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80',
    body: 'Minum soda berlebihan, menggigit kuku, dan sikat gigi terlalu keras adalah beberapa kebiasaan yang perlahan merusak enamel gigi tanpa disadari.',
    publishedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Article(
    id: 'art-3',
    categoryName: 'Nina Kidz',
    title: 'Program Nina Kidz: Menjaga Gigi Anak Sehat & Bebas Karies Sejak Dini',
    slug: 'program-nina-kidz',
    coverImageUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800&auto=format&fit=crop&q=80',
    body: 'Nina Kidz adalah program pemeriksaan gigi anak dengan pendekatan ramah anak, termasuk vitamin gigi dan fluoride treatment untuk mencegah karies sejak dini.',
    publishedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Article(
    id: 'art-4',
    categoryName: 'Perawatan Gigi',
    title: 'Prosedur Bleaching Gigi Instant: Rahasia Senyum Cerah Cemerlang',
    slug: 'prosedur-bleaching-gigi',
    coverImageUrl: 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80',
    body: 'Bleaching In-Office Whitening adalah solusi tercepat untuk mencerahkan warna gigi hingga 4-8 tingkat lebih putih hanya dalam 60 menit.',
    publishedAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
  Article(
    id: 'art-5',
    categoryName: 'Tips Kesehatan',
    title: 'Cara Memilih Sikat Gigi yang Tepat untuk Berbagai Usia',
    slug: 'cara-memilih-sikat-gigi',
    coverImageUrl: 'https://images.unsplash.com/photo-1559590656-b3f4d32c5869?w=800&auto=format&fit=crop&q=80',
    body: 'Memilih sikat gigi yang tepat sangat penting untuk menjaga kesehatan gigi dan gusi. Pelajari panduan lengkapnya di sini.',
    publishedAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];

final List<Promo> _fallbackPromos = [
  const Promo(
    id: 'pro-1',
    title: 'Promo Scaling 6-in-1 Super Clean',
    voucherCode: 'SCALING50K',
    discountValue: 50000,
    discountType: 'fixed',
    bannerImageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&auto=format&fit=crop&q=80',
    description: 'Paket scaling lengkap pembersihan karang gigi + polishing + fluoridasi hanya Rp149.000. Berlaku di seluruh cabang.',
    isActive: true,
  ),
  const Promo(
    id: 'pro-2',
    title: 'Diskon Pemasangan Behel Metal 10%',
    voucherCode: 'BEHEL10',
    discountValue: 10,
    discountType: 'percentage',
    bannerImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80',
    description: 'Diskon 10% untuk pemasangan behel metal konvensional via aplikasi mobile. Konsultasi gratis!',
    isActive: true,
  ),
  const Promo(
    id: 'pro-3',
    title: 'Voucher New Patient Senyum Sehat',
    voucherCode: 'SMILESEHAT',
    discountValue: 30000,
    discountType: 'fixed',
    bannerImageUrl: 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80',
    description: 'Potongan Rp 30.000 khusus pasien baru pertama kali berkunjung ke Nina Dental Care.',
    isActive: true,
  ),
  const Promo(
    id: 'pro-4',
    title: 'Bleaching Premium 50% OFF',
    voucherCode: 'BRIGHT50',
    discountValue: 50,
    discountType: 'percentage',
    bannerImageUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80',
    description: 'Dapatkan gigi putih cemerlang dengan diskon 50% untuk paket bleaching in-office bulan ini!',
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
