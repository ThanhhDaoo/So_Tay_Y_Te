import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Thanh điều hướng dưới cùng 5 mục với nút ICE nổi ở giữa.
class IceBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  const IceBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: AppColors.iceGlassSurface,
            border: Border(
              top: BorderSide(
                color: AppColors.iceCardBorder.withValues(alpha: 0.7),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  label: 'Thời gian',
                  iconAsset: 'assets/icons/ic_nav_timeline.svg',
                  isSelected: selectedIndex == 0,
                  onTap: () => onSelectTab(0),
                ),
                _NavItem(
                  label: 'Đơn thuốc',
                  iconAsset: 'assets/icons/ic_nav_prescription.svg',
                  isSelected: selectedIndex == 1,
                  onTap: () => onSelectTab(1),
                ),
                _CenterIceButton(
                  isSelected: selectedIndex == 2,
                  onTap: () => onSelectTab(2),
                ),
                _NavItem(
                  label: 'Hồ sơ',
                  iconAsset: 'assets/icons/ic_nav_profile.svg',
                  isSelected: selectedIndex == 3,
                  onTap: () => onSelectTab(3),
                ),
                _NavItem(
                  label: 'Cài đặt',
                  iconAsset: 'assets/icons/ic_nav_settings.svg',
                  isSelected: selectedIndex == 4,
                  onTap: () => onSelectTab(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.iceOlive : AppColors.iceTextMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterIceButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterIceButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.iceOlive,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.iceOlive.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_nav_ice.svg',
              width: 18,
              height: 18,
            ),
            const SizedBox(height: 1),
            const Text(
              'ICE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.iceAccentCream,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
