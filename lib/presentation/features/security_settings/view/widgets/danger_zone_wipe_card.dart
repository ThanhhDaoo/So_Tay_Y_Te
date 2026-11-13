import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/security_settings_state.dart';

class DangerZoneWipeCard extends StatelessWidget {
  final SecuritySettingsState state;
  final VoidCallback onWipeData;

  const DangerZoneWipeCard({
    super.key,
    required this.state,
    required this.onWipeData,
  });

  void _showConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.secDangerIconBg,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/ic_sec_danger_warning.svg',
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Xác nhận xóa dữ liệu?',
              style: AppTypography.heading3.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.secDangerText,
              ),
            ),
          ],
        ),
        content: Text(
          'Toàn bộ hồ sơ bệnh án, đơn thuốc, khóa mã hóa SQLCipher và sinh hiệu lưu trữ cục bộ sẽ bị hủy vĩnh viễn không thể khôi phục.',
          style: AppTypography.body.copyWith(
            fontSize: 13,
            color: AppColors.secOliveMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Hủy bỏ',
              style: AppTypography.labelSemiBold.copyWith(
                color: AppColors.secOliveMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onWipeData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secDangerText,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa toàn bộ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWiping = state.currentOperation == SecurityOperation.wipingData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secDangerBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secDangerIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/icons/ic_sec_danger_warning.svg',
                  width: 16,
                  height: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vùng Thao Tác Nguy Hiểm',
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Xóa sạch toàn bộ khóa mã hóa và cơ sở dữ liệu trên máy này. Hành động này không thể hoàn tác.',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        color: AppColors.secOliveMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Danger Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: isWiping ? null : () => _showConfirmDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.secDangerText,
                elevation: 1,
                side: const BorderSide(color: AppColors.secCardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: isWiping
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.secDangerText),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_sec_trash_wipe.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            AppColors.secDangerText,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Xóa Toàn Bộ Dữ Liệu Trên Thiết Bị',
                            style: AppTypography.labelSemiBold.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secDangerText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

