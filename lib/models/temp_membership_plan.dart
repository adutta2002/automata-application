class MembershipPlan {
  final int? id;
  final String name;
  final double price;
  final int durationMonths;
  final String description;

  MembershipPlan({
    this.id,
    required this.name,
    required this.price,
    required this.durationMonths,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration_months': durationMonths,
      'description': description,
    };
  }

  factory MembershipPlan.fromMap(Map<String, dynamic> map) {
    return MembershipPlan(
      id: map['id'],
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      durationMonths: map['duration_months'] ?? 1,
      description: map['description'] ?? '',
    );
  }
}
