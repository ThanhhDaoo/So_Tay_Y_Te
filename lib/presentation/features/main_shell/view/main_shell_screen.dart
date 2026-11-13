import 'package:flutter/material.dart';
import '../../documents/view/documents_screen.dart';
import '../../emergency_card/view/emergency_card_screen.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../prescriptions/view/prescriptions_screen.dart';
import '../../profile/view/profile_screen.dart';
import '../../timeline/view/timeline_screen.dart';

/// Màn hình khung chính giữ thanh điều hướng cố định và chuyển tab mượt bằng IndexedStack.
class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 2});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onSelectTab(int index) {
    if (index > 4) return;
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TimelineScreen(showBottomNav: false),
          PrescriptionsScreen(showBottomNav: false),
          EmergencyCardScreen(showBottomNav: false),
          ProfileScreen(showBottomNav: false),
          DocumentsScreen(showBottomNav: false),
        ],
      ),
      bottomNavigationBar: IceBottomNavBar(
        selectedIndex: _selectedIndex,
        onSelectTab: _onSelectTab,
      ),
    );
  }
}

