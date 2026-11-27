enum NutritionRuleType {
  shouldEat,
  shouldAvoid,
}

class NutritionGuideline {
  final String id;
  final String? userId;
  final String memberId;
  final NutritionRuleType type;
  final String healthTag; // 'Huyết áp & Tim mạch', 'Xương khớp', 'Đường huyết', 'Giấc ngủ & Tiêu hóa'
  final String foodName;
  final String recommendedAmount;
  final String benefitOrRisk;
  final String iconKey;
  final DateTime createdAt;

  const NutritionGuideline({
    required this.id,
    this.userId,
    this.memberId = 'primary',
    required this.type,
    required this.healthTag,
    required this.foodName,
    required this.recommendedAmount,
    required this.benefitOrRisk,
    this.iconKey = 'leaf',
    required this.createdAt,
  });

  bool get isShouldEat => type == NutritionRuleType.shouldEat;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? '',
      'member_id': memberId,
      'type': isShouldEat ? 'should_eat' : 'should_avoid',
      'health_tag': healthTag,
      'food_name': foodName,
      'recommended_amount': recommendedAmount,
      'benefit_or_risk': benefitOrRisk,
      'icon_name': iconKey,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NutritionGuideline.fromMap(Map<String, dynamic> map) {
    final rawType = (map['type'] as String?) ?? 'should_eat';
    return NutritionGuideline(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      memberId: (map['member_id'] as String?) ?? 'primary',
      type: rawType == 'should_avoid'
          ? NutritionRuleType.shouldAvoid
          : NutritionRuleType.shouldEat,
      healthTag: (map['health_tag'] as String?) ?? 'Huyết áp & Tim mạch',
      foodName: (map['food_name'] as String?) ?? '',
      recommendedAmount: (map['recommended_amount'] as String?) ?? 'Vừa phải',
      benefitOrRisk: (map['benefit_or_risk'] as String?) ?? '',
      iconKey: (map['icon_name'] as String?) ?? 'leaf',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

enum SupplementUsageStatus {
  usingNow,
  reference,
}

class DietarySupplement {
  final String id;
  final String? userId;
  final String memberId;
  final String productName;
  final String category;
  final String? imagePath;
  final String benefits;
  final String dosageGuide;
  final SupplementUsageStatus usageStatus;
  final String? cautionNote;
  final DateTime createdAt;

  const DietarySupplement({
    required this.id,
    this.userId,
    this.memberId = 'primary',
    required this.productName,
    required this.category,
    this.imagePath,
    required this.benefits,
    required this.dosageGuide,
    this.usageStatus = SupplementUsageStatus.usingNow,
    this.cautionNote,
    required this.createdAt,
  });

  bool get isUsingNow => usageStatus == SupplementUsageStatus.usingNow;

  DietarySupplement copyWith({
    String? productName,
    String? category,
    String? imagePath,
    String? benefits,
    String? dosageGuide,
    SupplementUsageStatus? usageStatus,
    String? cautionNote,
  }) {
    return DietarySupplement(
      id: id,
      userId: userId,
      memberId: memberId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      benefits: benefits ?? this.benefits,
      dosageGuide: dosageGuide ?? this.dosageGuide,
      usageStatus: usageStatus ?? this.usageStatus,
      cautionNote: cautionNote ?? this.cautionNote,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId ?? '',
      'member_id': memberId,
      'product_name': productName,
      'category': category,
      'image_path': imagePath,
      'benefits': benefits,
      'dosage_guide': dosageGuide,
      'usage_status': isUsingNow ? 'using' : 'reference',
      'caution_note': cautionNote,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DietarySupplement.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['usage_status'] as String?) ?? 'using';
    return DietarySupplement(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      memberId: (map['member_id'] as String?) ?? 'primary',
      productName: (map['product_name'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Hỗ trợ sức khỏe',
      imagePath: map['image_path'] as String?,
      benefits: (map['benefits'] as String?) ?? '',
      dosageGuide: (map['dosage_guide'] as String?) ?? '',
      usageStatus: rawStatus == 'reference'
          ? SupplementUsageStatus.reference
          : SupplementUsageStatus.usingNow,
      cautionNote: map['caution_note'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
