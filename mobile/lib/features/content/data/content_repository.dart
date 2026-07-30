import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'content_models.dart';

class ContentRepository {
  ContentRepository(this._dio);

  final Dio _dio;

  // The endpoint returns drafts/inactive rows too (it's the same list the
  // CMS admin page uses) — the patient app filters those out client-side so
  // it never shows unpublished content.
  Future<List<Article>> listArticles() async {
    final res = await _dio.get<List<dynamic>>('/content/articles');
    return (res.data ?? [])
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .where((a) => a.publishedAt != null)
        .toList();
  }

  Future<List<Promo>> listPromos() async {
    final res = await _dio.get<List<dynamic>>('/content/promos');
    return (res.data ?? [])
        .map((e) => Promo.fromJson(e as Map<String, dynamic>))
        .where((p) => p.isActive)
        .toList();
  }

  Future<List<Testimonial>> listTestimonials() async {
    final res = await _dio.get<List<dynamic>>('/content/testimonials');
    return (res.data ?? []).map((e) => Testimonial.fromJson(e as Map<String, dynamic>)).toList();
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
