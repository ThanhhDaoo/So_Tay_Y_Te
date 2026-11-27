import 'package:flutter/material.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Đồng bộ hoàn toàn thanh điều hướng cũ về chuẩn 4 mục SeniorBottomNavBar mới
/// (Trang chủ, Bệnh án, Thuốc uống, Tài khoản), loại bỏ thanh 5 mục có nút tròn ICE cũ.
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
    return SeniorBottomNavBar(
      selectedIndex: selectedIndex.clamp(0, 3),
      onSelectTab: onSelectTab,
    );
  }
}
