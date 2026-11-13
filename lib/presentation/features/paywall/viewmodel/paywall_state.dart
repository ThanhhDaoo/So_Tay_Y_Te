enum PlanType {
  yearly(
    id: 'yearly',
    title: 'Gói Năm',
    durationBadge: '12 Tháng',
    subtext: 'Chỉ khoảng ~33.000 đ/tháng',
    price: '399.000 đ',
    originalPrice: '720.000 đ',
    recommendedBadge: 'KHUYÊN DÙNG • TIẾT KIỆM 45%',
  ),
  monthly(
    id: 'monthly',
    title: 'Gói Hàng Tháng',
    subtext: 'Gia hạn tự động mỗi tháng',
    price: '59.000 đ',
    suffix: '/tháng',
  ),
  lifetime(
    id: 'lifetime',
    title: 'Gói Trọn Đời',
    durationBadge: 'VIP',
    subtext: 'Thanh toán 1 lần, dùng vĩnh viễn',
    price: '999.000 đ',
    suffix: 'Trọn gói',
  );

  const PlanType({
    required this.id,
    required this.title,
    this.durationBadge,
    required this.subtext,
    required this.price,
    this.originalPrice,
    this.suffix,
    this.recommendedBadge,
  });

  final String id;
  final String title;
  final String? durationBadge;
  final String subtext;
  final String price;
  final String? originalPrice;
  final String? suffix;
  final String? recommendedBadge;
}

class PaywallState {
  const PaywallState({
    this.selectedPlan = PlanType.yearly,
    this.isProcessing = false,
    this.linkedProvider,
  });

  final PlanType selectedPlan;
  final bool isProcessing;
  final String? linkedProvider;

  PaywallState copyWith({
    PlanType? selectedPlan,
    bool? isProcessing,
    String? linkedProvider,
  }) {
    return PaywallState(
      selectedPlan: selectedPlan ?? this.selectedPlan,
      isProcessing: isProcessing ?? this.isProcessing,
      linkedProvider: linkedProvider ?? this.linkedProvider,
    );
  }
}

