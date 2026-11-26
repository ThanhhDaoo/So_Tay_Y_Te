import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../viewmodel/emergency_card_state.dart';
import '../viewmodel/emergency_card_viewmodel.dart';
import 'widgets/ice_allergy_warning_card.dart';
import 'widgets/ice_bottom_nav_bar.dart';
import 'widgets/ice_call_actions_section.dart';
import 'widgets/ice_chronic_conditions_card.dart';
import 'widgets/ice_emergency_banner.dart';
import 'widgets/ice_header.dart';
import 'widgets/ice_lockscreen_widget_card.dart';
import 'widgets/ice_patient_snapshot_card.dart';
import 'widgets/ice_qr_module_card.dart';

/// Màn hình Thẻ Cấp Cứu Khẩn Cấp (ICE) theo kiến trúc MVVM.
class EmergencyCardScreen extends StatefulWidget {
  final bool showBottomNav;
  final bool readOnlyLockMode;

  const EmergencyCardScreen({
    super.key,
    this.showBottomNav = true,
    this.readOnlyLockMode = false,
  });

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  late final EmergencyCardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EmergencyCardViewModel()..addListener(_onViewModelChanged);
    _viewModel.loadProfile();
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_onViewModelChanged)
      ..dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final message = _viewModel.state.lastActionMessage;
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.iceOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    _viewModel.clearActionMessage();
  }

  String _buildEmergencyQrPayload(EmergencyCardState state) {
    final conditions = state.chronicConditions.map((c) => c.title).join(', ');
    return 'STYT-ICE | BN: ${state.patient.fullName} | Máu: ${state.patient.bloodType} (${state.patient.rhFactor}) | Dị ứng: ${state.allergyWarning.title} | Bệnh nền: ${conditions.isNotEmpty ? conditions : "Không"} | ICE: ${state.primaryContact.phone.isNotEmpty ? state.primaryContact.phone : "115"}';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              ListView(
                padding: EdgeInsets.only(
                  top: topPadding + 78,
                  bottom: bottomPadding + 96,
                  left: AppLayoutTokens.screenPadding,
                  right: AppLayoutTokens.screenPadding,
                ),
                children: [
                  // Cụm 1: Hành động gọi cấp cứu 1 chạm
                  const IceEmergencyBanner(),
                  const SizedBox(height: AppLayoutTokens.cardGap),
                  IceCallActionsSection(
                    primaryContact: state.primaryContact,
                    doctorContact: state.doctorContact,
                    hotline115: state.hotline115,
                    onCallPrimary: _viewModel.callPrimaryContact,
                    onCallDoctor: _viewModel.callDoctor,
                    onCall115: _viewModel.callEmergency115,
                  ),
                  const SizedBox(height: AppLayoutTokens.sectionGap),

                  // Cụm 2: Dữ liệu sinh tồn cốt lõi (Định danh + Nhóm máu + Dị ứng + Bệnh nền)
                  SectionContainer(
                    title: 'Thông tin lâm sàng sống còn',
                    icon: Icons.medical_information_outlined,
                    bottomSpacing: AppLayoutTokens.sectionGap,
                    child: Column(
                      children: [
                        IcePatientSnapshotCard(patient: state.patient),
                        const SizedBox(height: AppLayoutTokens.cardGap),
                        IceAllergyWarningCard(warning: state.allergyWarning),
                        const SizedBox(height: AppLayoutTokens.cardGap),
                        IceChronicConditionsCard(
                          conditions: state.chronicConditions,
                        ),
                      ],
                    ),
                  ),

                  // Cụm 3: Mã QR Bác sĩ & Hiển thị màn hình khóa
                  SectionContainer(
                    title: 'Chia sẻ nhanh & Tiện ích',
                    icon: Icons.qr_code_scanner_rounded,
                    bottomSpacing: 20,
                    child: Column(
                      children: [
                        IceQrModuleCard(
                          qrPayload: _buildEmergencyQrPayload(state),
                          onExpandQr: () => showFullScreenEmergencyQrDialog(
                            context,
                            qrPayload: _buildEmergencyQrPayload(state),
                          ),
                        ),
                        if (!widget.readOnlyLockMode) ...[
                          const SizedBox(height: AppLayoutTokens.cardGap),
                          IceLockScreenWidgetCard(
                            isEnabled: state.isLockScreenWidgetEnabled,
                            onToggle: _viewModel.toggleLockScreenWidget,
                          ),
                        ],
                      ],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_verified_shield.svg',
                        width: 10,
                        height: 12.5,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          state.verifiedFooterText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IceHeader(
                  readOnlyLockMode: widget.readOnlyLockMode,
                  onBackToLock: () => Navigator.of(context).maybePop(),
                ),
              ),
              if (widget.showBottomNav && !widget.readOnlyLockMode)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IceBottomNavBar(
                    selectedIndex: state.selectedNavIndex,
                    onSelectTab: (index) {
                      if (index == 2) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainShellScreen(initialIndex: index),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
