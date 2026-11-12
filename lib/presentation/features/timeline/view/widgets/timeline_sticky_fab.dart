import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Nút nổi cố định phía trên thanh điều hướng: "Thêm Đợt Khám Mới".
class TimelineStickyFab extends StatelessWidget {
  final VoidCallback onPressed;

  const TimelineStickyFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.timelineOlive,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.timelineOlive.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_add_circle_white.svg',
                width: 18.33,
                height: 18.33,
              ),
              const SizedBox(width: 8),
              const Text(
                'Thêm Đợt Khám Mới',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

