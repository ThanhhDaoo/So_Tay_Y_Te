import 'package:flutter/material.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../../assistant/view/medical_assistant_sheet.dart';
import '../../home/view/home_screen.dart';
import '../../medical_dossier/view/medical_dossier_screen.dart';
import '../../prescriptions/view/prescriptions_screen.dart';
import '../../profile/view/profile_screen.dart';

/// Màn hình khung chính chuẩn người lớn tuổi (40+):
/// Tối đa 4 mục trên thanh Bottom Navigation chữ to, icon lớn (Trang chủ, Bệnh án, Thuốc uống, Tài khoản).
class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 3);
    AppSessionNotifier.instance.initFromSession();
  }

  void _onSelectTab(int index) {
    if (index < 0 || index > 3) return;
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
    final assistantBottomOffset =
        _selectedIndex == 1 ? bottomPadding + 150 : bottomPadding + 92;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              HomeScreen(onSelectMainTab: _onSelectTab),
              const MedicalDossierScreen(showBottomNav: false),
              const PrescriptionsScreen(showBottomNav: false),
              const ProfileScreen(showBottomNav: false),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            right: AppLayoutTokens.screenPadding,
            bottom: assistantBottomOffset,
            child: _FloatingAssistantButton(onTap: _openAssistant),
          ),
        ],
      ),
      bottomNavigationBar: SeniorBottomNavBar(
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
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
              width: 1.3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D1E241B),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: Color(0xFFFFE0A3),
                size: 26,
              ),
              SizedBox(width: 8),
              Text(
                'Hỏi Trợ lý Y tế',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
