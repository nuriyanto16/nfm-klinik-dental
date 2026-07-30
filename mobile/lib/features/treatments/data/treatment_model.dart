class Treatment {
  const Treatment({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
  });

  final String id;
  final String name;
  final String categoryName;
  final double price;
  final int durationMinutes;
  final bool isActive;

  factory Treatment.fromJson(Map<String, dynamic> json) => Treatment(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryName: json['categoryName'] as String,
        price: (json['price'] as num).toDouble(),
        durationMinutes: json['durationMinutes'] as int,
        isActive: json['isActive'] as bool,
      );
}
