import 'package:flutter/material.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../assistant/view/medical_assistant_sheet.dart';
import '../../emergency_card/view/emergency_card_screen.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../prescriptions/view/prescriptions_screen.dart';
import '../../profile/view/profile_screen.dart';
import '../../timeline/view/timeline_screen.dart';
import '../../security_settings/view/security_settings_screen.dart';

/// Màn hình khung chính giữ thanh điều hướng cố định, chuyển tab mượt bằng IndexedStack
/// và tích hợp nút mở nhanh Trợ Lý Sổ Tay Y Tế (Chatbox).
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
    AppSessionNotifier.instance.initFromSession();
  }

  void _onSelectTab(int index) {
    if (index > 4) return;
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAssistant() {
    MedicalAssistantSheet.show(
      context,
      onSwitchMainTab: _onSelectTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // Trên tab 0 (Timeline) có sẵn nút FAB "+ Thêm bệnh án" ở bottomPadding + 76,
    // nên nút Trợ lý tự nâng cao hơn để không bao giờ đè lên nút thêm bệnh án.
    final assistantBottomOffset =
        _selectedIndex == 0 ? bottomPadding + 140 : bottomPadding + 82;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              const TimelineScreen(showBottomNav: false),
              const PrescriptionsScreen(showBottomNav: false),
              const EmergencyCardScreen(showBottomNav: false),
              const ProfileScreen(showBottomNav: false),
              SecuritySettingsScreen(
                showBottomNav: false,
                onSelectMainTab: _onSelectTab,
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: assistantBottomOffset,
            child: _FloatingAssistantButton(onTap: _openAssistant),
          ),
        ],
      ),
      bottomNavigationBar: IceBottomNavBar(
        selectedIndex: _selectedIndex,
        onSelectTab: _onSelectTab,
      ),
    );
  }
}

class _FloatingAssistantButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingAssistantButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C2418),
                Color(0xFF4E5547),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFD8B278),
              width: 1.1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x331E241B),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFFFFE0A3),
                size: 17,
              ),
              SizedBox(width: 6),
              Text(
                'Trợ lý',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
