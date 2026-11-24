import 'package:flutter/material.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/paywall_viewmodel.dart';
import 'widgets/account_linking_card.dart';
import 'widgets/paywall_header.dart';
import 'widgets/trust_assurances_row.dart';
import 'widgets/vault_brand_hero.dart';
import 'widgets/vault_cta_button.dart';
import 'widgets/vault_features_checklist.dart';
import 'widgets/vault_pricing_selector.dart';
import 'widgets/vault_pro_payment_sheet.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late final PaywallViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PaywallViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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

  void _onStartTrial() {
    final plan = _viewModel.state.selectedPlan;
    VaultProPaymentSheet.show(
      context,
      selectedPlan: plan,
      viewModel: _viewModel,
      onSuccess: () {
        _showSnack(
          'Chúc mừng bạn đã nâng cấp thành công ${plan.title}! Toàn bộ tính năng Pro đã được mở khóa.',
        );
      },
    );
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
                slivers: [
                  SliverToBoxAdapter(
                    child: PaywallHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      onProfileTap: () {
                        final activeName = AppSessionNotifier.instance.fullName?.trim();
                        final displayName = (activeName != null && activeName.isNotEmpty)
                            ? activeName
                            : 'Hồ sơ hiện tại';
                        final tierLabel = state.isPro ? 'Gói Vault Pro' : 'Gói Free';
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
                    sliver: SliverList.list(
                      children: [
                        if (state.isPro) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF81C784)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tài khoản của bạn đã được nâng cấp Vault Pro!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B5E20),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
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
                          onStartTrial: _onStartTrial,
                          isProcessing: state.isProcessing,
                        ),
                        const SizedBox(height: 22),
                        AccountLinkingCard(
                          linkedProvider: state.linkedProvider,
                          onLinkGoogle: () async {
                            await _viewModel.linkAccount('Google');
                            _showSnack(
                              'Đã liên kết Google Account thành công!',
                            );
                          },
                          onLinkApple: () async {
                            await _viewModel.linkAccount('Apple');
                            _showSnack(
                              'Đã liên kết Apple ID thành công!',
                            );
                          },
                          onLinkPhone: () async {
                            await _viewModel.linkAccount('Phone');
                            _showSnack(
                              'Đã xác thực OTP Số điện thoại thành công!',
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const TrustAssurancesRow(),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: state.isProcessing ? null : _onRestorePurchases,
                            icon: const Icon(Icons.restore_rounded, size: 16, color: Color(0xFF4E5547)),
                            label: const Text(
                              'Khôi phục giao dịch mua trước đây',
                              style: TextStyle(color: Color(0xFF4E5547), fontSize: 13, fontWeight: FontWeight.w600),
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
