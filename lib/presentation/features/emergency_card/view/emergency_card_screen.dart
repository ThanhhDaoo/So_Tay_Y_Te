import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
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
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  late final EmergencyCardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EmergencyCardViewModel()..addListener(_onViewModelChanged);
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
                  bottom: bottomPadding + 88,
                  left: 16,
                  right: 16,
                ),
                children: [
                  const IceEmergencyBanner(),
                  const SizedBox(height: 16),
                  IceCallActionsSection(
                    primaryContact: state.primaryContact,
                    doctorContact: state.doctorContact,
                    hotline115: state.hotline115,
                    onCallPrimary: _viewModel.callPrimaryContact,
                    onCallDoctor: _viewModel.callDoctor,
                    onCall115: _viewModel.callEmergency115,
                  ),
                  const SizedBox(height: 16),
                  IcePatientSnapshotCard(patient: state.patient),
                  const SizedBox(height: 16),
                  IceAllergyWarningCard(warning: state.allergyWarning),
                  const SizedBox(height: 16),
                  IceChronicConditionsCard(
                    conditions: state.chronicConditions,
                  ),
                  const SizedBox(height: 16),
                  IceQrModuleCard(
                    onExpandQr: () => showFullScreenEmergencyQrDialog(context),
                  ),
                  const SizedBox(height: 16),
                  IceLockScreenWidgetCard(
                    isEnabled: state.isLockScreenWidgetEnabled,
                    onToggle: _viewModel.toggleLockScreenWidget,
                  ),
                  const SizedBox(height: 16),
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
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IceHeader(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IceBottomNavBar(
                  selectedIndex: state.selectedNavIndex,
                  onSelectTab: (index) {
                    if (index == 0) {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.timeline,
                      );
                      return;
                    }
                    _viewModel.selectNavIndex(index);
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
