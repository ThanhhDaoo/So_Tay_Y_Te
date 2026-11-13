import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/paywall_state.dart';

class VaultPricingSelector extends StatelessWidget {
  const VaultPricingSelector({
    super.key,
    required this.selectedPlan,
    required this.onSelectPlan,
  });

  final PlanType selectedPlan;
  final ValueChanged<PlanType> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _YearlyPlanCard(
          isSelected: selectedPlan == PlanType.yearly,
          onTap: () => onSelectPlan(PlanType.yearly),
        ),
        const SizedBox(height: 12),
        _SimplePlanCard(
          plan: PlanType.monthly,
          isSelected: selectedPlan == PlanType.monthly,
          onTap: () => onSelectPlan(PlanType.monthly),
        ),
        const SizedBox(height: 12),
        _SimplePlanCard(
          plan: PlanType.lifetime,
          isSelected: selectedPlan == PlanType.lifetime,
          onTap: () => onSelectPlan(PlanType.lifetime),
          backgroundColor: const Color(0xFFF5F0E6),
        ),
      ],
    );
  }
}

class _YearlyPlanCard extends StatelessWidget {
  const _YearlyPlanCard({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.iceAccentCream
                      : const Color(0xFFECE7DF),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4E5547)
                          : const Color(0xFFD3E4FE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        isSelected
                            ? 'assets/icons/ic_vault_radio_checked.svg'
                            : 'assets/icons/ic_vault_radio_unchecked.svg',
                        width: 10,
                        height: 8,
                        colorFilter: ColorFilter.mode(
                          isSelected ? Colors.white : const Color(0xFF3D4947),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Gói Năm',
                              style: AppTypography.heading3.copyWith(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.iceTextNavy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6EFE5),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFE8D2B5),
                                ),
                              ),
                              child: Text(
                                '12 Tháng',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.44,
                                  color: const Color(0xFF4E5547),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chỉ khoảng ~33.000 đ/tháng',
                          style: AppTypography.body.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF3D4947),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '399.000 đ',
                        style: AppTypography.heading3.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4E5547),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '720.000 đ',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                          color: const Color(0xFF6D7A77),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -11,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.iceAccentCream,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD9BE9E)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              'KHUYÊN DÙNG • TIẾT KIỆM 45%',
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: const Color(0xFF3A2F20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimplePlanCard extends StatelessWidget {
  const _SimplePlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
    this.backgroundColor,
  });

  final PlanType plan;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFFBF9F4);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4E5547)
                  : const Color(0xFFE8D2B5),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4E5547)
                      : const Color(0xFFD3E4FE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    isSelected
                        ? 'assets/icons/ic_vault_radio_checked.svg'
                        : 'assets/icons/ic_vault_radio_unchecked.svg',
                    width: 10,
                    height: 8,
                    colorFilter: ColorFilter.mode(
                      isSelected ? Colors.white : const Color(0xFF3D4947),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.title,
                          style: AppTypography.heading3.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                        if (plan.durationBadge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4E5547),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              plan.durationBadge!,
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.subtext,
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF3D4947),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan.price,
                    style: AppTypography.heading3.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                  if (plan.suffix != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      plan.suffix!,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D4947),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
