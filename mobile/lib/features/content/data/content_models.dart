class Article {
  const Article({
    required this.id,
    this.categoryName,
    required this.title,
    required this.slug,
    this.coverImageUrl,
    required this.body,
    this.publishedAt,
  });

  final String id;
  final String? categoryName;
  final String title;
  final String slug;
  final String? coverImageUrl;
  final String body;
  final DateTime? publishedAt;

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        categoryName: json['categoryName'] as String?,
        title: json['title'] as String,
        slug: json['slug'] as String,
        coverImageUrl: json['coverImageUrl'] as String?,
        body: json['body'] as String,
        publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
      );
}

class Promo {
  const Promo({
    required this.id,
    required this.title,
    this.bannerImageUrl,
    this.description,
    required this.isActive,
    this.voucherCode,
    this.discountValue,
    this.discountType,
  });

  final String id;
  final String title;
  final String? bannerImageUrl;
  final String? description;
  final bool isActive;
  final String? voucherCode;
  final double? discountValue;
  final String? discountType;

  factory Promo.fromJson(Map<String, dynamic> json) => Promo(
        id: json['id'] as String,
        title: json['title'] as String,
        bannerImageUrl: json['bannerImageUrl'] as String?,
        description: json['description'] as String?,
        isActive: json['isActive'] as bool,
        voucherCode: json['voucherCode'] as String?,
        discountValue: json['discountValue'] != null ? (json['discountValue'] as num).toDouble() : null,
        discountType: json['discountType'] as String?,
      );
}

class Testimonial {
  const Testimonial({
    required this.id,
    required this.patientName,
    this.doctorName,
    this.photoUrl,
    required this.rating,
    required this.quote,
  });

  final String id;
  final String patientName;
  final String? doctorName;
  final String? photoUrl;
  final int rating;
  final String quote;

  factory Testimonial.fromJson(Map<String, dynamic> json) => Testimonial(
        id: json['id'] as String,
        patientName: json['patientName'] as String,
        doctorName: json['doctorName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        rating: json['rating'] as int,
        quote: json['quote'] as String,
      );
}
