class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.slug,
    required this.address,
    required this.city,
    this.phone,
    required this.opensAt,
    required this.closesAt,
    required this.isActive,
  });

  final String id;
  final String name;
  final String slug;
  final String address;
  final String city;
  final String? phone;
  final String opensAt;
  final String closesAt;
  final bool isActive;

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
        phone: json['phone'] as String?,
        opensAt: (json['opensAt'] as String).substring(0, 5),
        closesAt: (json['closesAt'] as String).substring(0, 5),
        isActive: json['isActive'] as bool,
      );
}
