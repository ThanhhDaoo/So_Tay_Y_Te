import 'package:flutter/material.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/paywall_state.dart';
import '../viewmodel/paywall_viewmodel.dart';
import 'widgets/account_linking_card.dart';
import 'widgets/paywall_header.dart';
import 'widgets/trust_assurances_row.dart';
import 'widgets/vault_brand_hero.dart';
import 'widgets/vault_cta_button.dart';
import 'widgets/vault_features_checklist.dart';
import 'widgets/vault_pricing_selector.dart';
import 'widgets/vault_pro_active_dashboard.dart';
import 'widgets/vault_pro_payment_sheet.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late final PaywallViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = PaywallViewModel();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.iceOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onStartTrial([PlanType? overridePlan]) {
    final plan = overridePlan ?? _viewModel.state.selectedPlan;
    VaultProPaymentSheet.show(
      context,
      selectedPlan: plan,
      viewModel: _viewModel,
      onSuccess: () {
        _scrollToTop();
        _showSnack(
          'Chúc mừng bạn đã nâng cấp thành công ${plan.title}! Đã chuyển sang giao diện Vault Pro.',
        );
      },
    );
  }

  void _onChangePlanWhenActive() {
    final current = _viewModel.state.activePlan ?? _viewModel.state.selectedPlan;
    final nextPlan = switch (current) {
      PlanType.monthly => PlanType.yearly,
      PlanType.yearly => PlanType.lifetime,
      PlanType.lifetime => PlanType.yearly,
    };
    _viewModel.selectPlan(nextPlan);
    _onStartTrial(nextPlan);
  }

  Future<void> _confirmResetProForTesting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset về Gói Free?'),
        content: const Text(
          'Thao tác này sẽ hủy trạng thái Vault Pro giả lập trên máy để bạn kiểm thử lại quy trình thanh toán từ đầu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ Pro'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset về Free'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _viewModel.resetProForTesting();
      if (mounted) {
        _scrollToTop();
        _showSnack('Đã quay về giao diện Gói Free. Bạn có thể test thanh toán lại!');
      }
    }
  }

  Future<void> _onRestorePurchases() async {
    final success = await _viewModel.restorePurchases();
    if (success) {
      _showSnack('Đã khôi phục thành công gói đăng ký Vault Pro!');
    } else {
      _showSnack('Không tìm thấy thông tin đăng ký hợp lệ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          return Stack(
            children: [
              // Subtle background atmospheric glows
              Positioned(
                top: -48,
                right: -32,
                child: Container(
                  width: 224,
                  height: 224,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.iceAccentCream.withValues(alpha: 0.45),
                        AppColors.iceAccentCream.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 480,
                left: -48,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.iceAccentCream.withValues(alpha: 0.35),
                        AppColors.iceAccentCream.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: PaywallHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      onProfileTap: () {
                        final activeName =
                            AppSessionNotifier.instance.fullName?.trim();
                        final displayName =
                            (activeName != null && activeName.isNotEmpty)
                                ? activeName
                                : 'Hồ sơ hiện tại';
                        final tierLabel =
                            state.isPro ? 'Gói Vault Pro' : 'Gói Free';
                        _showSnack('Tài khoản: $displayName ($tierLabel)');
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      20,
                      16,
                      32 + bottomPadding,
                    ),
                    sliver: state.isPro
                        ? SliverList.list(
                            children: [
                              VaultProActiveDashboard(
                                key: const ValueKey('pro_active_view'),
                                state: state,
                                onChangePlanTap: _onChangePlanWhenActive,
                                onResetForTesting: _confirmResetProForTesting,
                              ),
                            ],
                          )
                        : SliverList.list(
                            children: [
                              const VaultBrandHero(),
                              const SizedBox(height: 22),
                              const VaultFeaturesChecklist(),
                              const SizedBox(height: 22),
                              VaultPricingSelector(
                                selectedPlan: state.selectedPlan,
                                onSelectPlan: _viewModel.selectPlan,
                              ),
                              const SizedBox(height: 20),
                              VaultCtaButton(
                                onStartTrial: () => _onStartTrial(),
                                isProcessing: state.isProcessing,
                              ),
                              const SizedBox(height: 22),
                              AccountLinkingCard(
                                linkedProvider: state.linkedProvider,
                                onLinkGoogle: () async {
                                  final ok =
                                      await _viewModel.linkAccount('Google');
                                  if (mounted &&
                                      _viewModel.state.feedbackMessage !=
                                          null) {
                                    _showSnack(
                                      ok
                                          ? 'Đã liên kết Google Account thành công!'
                                          : _viewModel.state.feedbackMessage!,
                                    );
                                  }
                                },
                                onLinkApple: () async {
                                  final ok =
                                      await _viewModel.linkAccount('Apple');
                                  if (mounted &&
                                      _viewModel.state.feedbackMessage !=
                                          null) {
                                    _showSnack(
                                      ok
                                          ? 'Đã liên kết Apple ID thành công!'
                                          : _viewModel.state.feedbackMessage!,
                                    );
                                  }
                                },
                                onLinkPhone: () async {
                                  final ok =
                                      await _viewModel.linkAccount('Phone');
                                  if (mounted &&
                                      _viewModel.state.feedbackMessage !=
                                          null) {
                                    _showSnack(
                                      ok
                                          ? 'Đã xác thực OTP Số điện thoại thành công!'
                                          : _viewModel.state.feedbackMessage!,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              const TrustAssurancesRow(),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton.icon(
                                  onPressed: state.isProcessing
                                      ? null
                                      : _onRestorePurchases,
                                  icon: const Icon(
                                    Icons.restore_rounded,
                                    size: 16,
                                    color: Color(0xFF4E5547),
                                  ),
                                  label: const Text(
                                    'Khôi phục giao dịch mua trước đây',
                                    style: TextStyle(
                                      color: Color(0xFF4E5547),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
