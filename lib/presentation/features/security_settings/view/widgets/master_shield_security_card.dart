import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/security_settings_state.dart';

class MasterShieldSecurityCard extends StatelessWidget {
  final SecuritySettingsState state;

  const MasterShieldSecurityCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      gradient: const LinearGradient(
        begin: Alignment(-0.7, -0.7),
        end: Alignment(0.7, 0.7),
        colors: [
          AppColors.secCardGradientStart,
          AppColors.secCardGradientEnd,
        ],
      ),
      borderColor: AppColors.secCardBorder,
      padding: const EdgeInsets.all(AppLayoutTokens.heroCardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secItemBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/ic_sec_master_shield.svg',
                  width: 22,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRUNG TÂM AN TOÀN DỮ LIỆU',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.secOlive,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Bảo vệ Tối đa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secItemBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_sec_verified_check.svg',
                      width: 13,
                      height: 13,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ĐÃ XÁC THỰC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: AppColors.secOlive,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Khóa máy phần cứng (Enclave)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secOliveMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secPillActive,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.secPillActiveText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
