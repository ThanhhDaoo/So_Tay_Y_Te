import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/user_session_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/clinical_qr_code_widget.dart';
import '../../../../../data/datasources/local/app_preferences_datasource.dart';
import '../../viewmodel/paywall_state.dart';
import '../../viewmodel/paywall_viewmodel.dart';

class VaultProPaymentSheet extends StatefulWidget {
  final PlanType selectedPlan;
  final VoidCallback onSuccess;
  final PaywallViewModel? viewModel;

  const VaultProPaymentSheet({
    super.key,
    required this.selectedPlan,
    required this.onSuccess,
    this.viewModel,
  });

  static void show(
    BuildContext context, {
    required PlanType selectedPlan,
    required VoidCallback onSuccess,
    PaywallViewModel? viewModel,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VaultProPaymentSheet(
        selectedPlan: selectedPlan,
        onSuccess: onSuccess,
        viewModel: viewModel,
      ),
    );
  }

  @override
  State<VaultProPaymentSheet> createState() => _VaultProPaymentSheetState();
}

class _VaultProPaymentSheetState extends State<VaultProPaymentSheet> {
  int _selectedMethod = 0; // 0: Apple Pay, 1: Visa/Master, 2: Momo, 3: VietQR
  bool _isProcessing = false;
  int _processingStage = 0; // 0: idle, 1: connecting, 2: verifying, 3: success
  String? _errorMessage;

  bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  String get _selectedMethodLabel {
    switch (_selectedMethod) {
      case 0:
        return 'Apple Pay (Sandbox)';
      case 1:
        return 'Visa / Mastercard (••4242)';
      case 2:
        return 'Ví MoMo (QR Sandbox)';
      case 3:
        return 'Chuyển khoản VietQR';
      default:
        return 'Apple Pay';
    }
  }

  Future<void> _confirmPayment() async {
    setState(() {
      _isProcessing = true;
      _processingStage = 1;
      _errorMessage = null;
    });

    if (!_isFlutterTest) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _processingStage = 2);
    }

    bool ok = true;
    if (widget.viewModel != null) {
      ok = await widget.viewModel!.subscribeToPlan(
        widget.selectedPlan,
        paymentMethod: _selectedMethodLabel,
      );
    } else {
      if (sl.isRegistered<AppPreferencesDataSource>()) {
        final prefs = sl<AppPreferencesDataSource>();
        await prefs.setProStatus(true);
        await prefs.saveProSubscriptionInfo(
          planId: widget.selectedPlan.id,
          paymentMethod: _selectedMethodLabel,
          transactionCode: 'VP-DEMO-8899',
          activatedAt: DateTime.now(),
        );
      }
      AppSessionNotifier.instance.setProStatus(
        true,
        planTitle: widget.selectedPlan.title,
      );
    }

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _isProcessing = false;
        _processingStage = 0;
        _errorMessage = widget.viewModel?.state.feedbackMessage ??
            'Giao dịch chưa hoàn tất. Vui lòng thử lại.';
      });
      return;
    }

    if (!_isFlutterTest) {
      setState(() => _processingStage = 3);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
    }

    setState(() {
      _isProcessing = false;
      _processingStage = 0;
    });
    Navigator.pop(context);
    widget.onSuccess();
  }

  String get _processingLabel {
    switch (_processingStage) {
      case 1:
        return 'Đang kết nối cổng thanh toán...';
      case 2:
        return 'Đang xác thực & kích hoạt Vault Pro...';
      case 3:
        return 'Thanh toán thành công! Đang mở Vault Pro...';
      default:
        return 'Đang xử lý...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Color(0xFFC59B27),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Xác Nhận Đăng Ký Vault Pro',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: const Text(
                          'TEST MODE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.iceTextMuted),
                  onPressed: _isProcessing ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1, color: AppColors.iceCardBorder),
            const SizedBox(height: 12),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan details summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.selectedPlan.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.selectedPlan == PlanType.lifetime
                                      ? 'Mở khóa vĩnh viễn • Không gia hạn lại'
                                      : 'Dùng thử miễn phí 7 ngày đầu • ${widget.selectedPlan.subtext}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.selectedPlan.price,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Methods
                    const Text(
                      'Chọn Phương Thức Thanh Toán (Giả lập)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMethodItem(
                      0,
                      'Apple Pay',
                      Icons.apple,
                      'Xác thực nhanh bằng Face ID / Touch ID (Sandbox)',
                    ),
                    _buildMethodItem(
                      1,
                      'Thẻ Tín Dụng / Ghi Nợ (Visa, Mastercard)',
                      Icons.credit_card,
                      'Thẻ test mặc định •••• 4242',
                    ),
                    _buildMethodItem(
                      2,
                      'Ví Điện Tử MoMo',
                      Icons.account_balance_wallet,
                      'Hiển thị mã QR MoMo giả lập',
                    ),
                    _buildMethodItem(
                      3,
                      'Chuyển Khoản Ngân Hàng (VietQR)',
                      Icons.qr_code_scanner,
                      'Hiển thị mã QR ngân hàng tự động kích hoạt',
                    ),

                    const SizedBox(height: 6),
                    _buildMethodSimulationPreview(),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Pinned Submit CTA (always visible without scrolling)
            ElevatedButton(
              onPressed: _isProcessing ? null : _confirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _processingStage == 3
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF0F172A),
                disabledBackgroundColor: _processingStage == 3
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_processingStage == 3)
                          const Icon(Icons.check_circle, color: Colors.white, size: 20)
                        else
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _processingLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.selectedPlan == PlanType.lifetime
                                ? 'Thanh Toán & Mở Khóa Ngay (${widget.selectedPlan.price})'
                                : 'Kích Hoạt Dùng Thử 7 Ngày (0đ)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Chế độ kiểm thử giả lập (0đ thật) • Có thể hủy & reset bất cứ lúc nào.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.iceTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSimulationPreview() {
    if (_selectedMethod == 2 || _selectedMethod == 3) {
      final isMomo = _selectedMethod == 2;
      final qrData =
          'SOTAYYTE|PLAN:${widget.selectedPlan.id}|PRICE:${widget.selectedPlan.price}|METHOD:${isMomo ? "MOMO" : "VIETQR"}';
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ClinicalQrCodeWidget(
                data: qrData,
                size: 82,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMomo ? 'Mã QR MoMo Giả Lập' : 'Mã VietQR Giả Lập',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nội dung: SOTAY ${widget.selectedPlan.id.toUpperCase()}\nSố tiền: ${widget.selectedPlan.price}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.iceTextSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bấm nút bên dưới để giả lập đã chuyển khoản thành công.',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedMethod == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF1E56A0)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Thẻ Sandbox: 4242 •••• •••• 4242  |  HSD: 12/29  |  Không trừ tiền thật',
                style: TextStyle(fontSize: 11.5, color: AppColors.iceTextSlate),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.face_retouching_natural, size: 18, color: Color(0xFF1E56A0)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Apple Pay Sandbox: Mô phỏng xác thực nhanh, không phát sinh phí trên Apple ID.',
              style: TextStyle(fontSize: 11.5, color: AppColors.iceTextSlate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem(
    int index,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedMethod == index;

    return InkWell(
      onTap: _isProcessing ? null : () => setState(() => _selectedMethod = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.iceOlive.withValues(alpha: 0.08)
              : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.iceOlive : AppColors.iceCardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.iceOlive : AppColors.iceTextSlate,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.iceTextSlate,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.iceOlive : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.iceOlive : AppColors.iceTextMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
