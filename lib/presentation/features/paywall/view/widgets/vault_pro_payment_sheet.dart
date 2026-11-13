import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodel/paywall_state.dart';

class VaultProPaymentSheet extends StatefulWidget {
  final PlanType selectedPlan;
  final VoidCallback onSuccess;

  const VaultProPaymentSheet({
    super.key,
    required this.selectedPlan,
    required this.onSuccess,
  });

  static void show(
    BuildContext context, {
    required PlanType selectedPlan,
    required VoidCallback onSuccess,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VaultProPaymentSheet(
        selectedPlan: selectedPlan,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<VaultProPaymentSheet> createState() => _VaultProPaymentSheetState();
}

class _VaultProPaymentSheetState extends State<VaultProPaymentSheet> {
  int _selectedMethod = 0; // 0: Apple Pay, 1: Visa/Master, 2: Momo, 3: VietQR
  bool _isProcessing = false;

  void _confirmPayment() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.pop(context);
        widget.onSuccess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.workspace_premium, color: Color(0xFFC59B27), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Xác Nhận Đăng Ký Vault Pro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.iceTextMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.iceCardBorder),
          const SizedBox(height: 16),

          // Plan details summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.selectedPlan.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 2),
                    const Text('Dùng thử miễn phí 7 ngày đầu', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                  ],
                ),
                Text(
                  widget.selectedPlan.price,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Methods
          const Text(
            'Chọn Phương Thức Thanh Toán',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
          ),
          const SizedBox(height: 10),
          _buildMethodItem(0, 'Apple Pay', Icons.apple, 'Xác thực nhanh bằng Face ID / Touch ID'),
          _buildMethodItem(1, 'Thẻ Tín Dụng / Ghi Nợ (Visa, Mastercard)', Icons.credit_card, 'Miễn phí chuyển đổi ngoại tệ'),
          _buildMethodItem(2, 'Ví Điện Tử MoMo', Icons.account_balance_wallet, 'Quét mã thanh toán tức thì'),
          _buildMethodItem(3, 'Chuyển Khoản Ngân Hàng (VietQR)', Icons.qr_code_scanner, 'Tự động kích hoạt trong 30 giây'),
          const SizedBox(height: 24),

          // Submit CTA
          ElevatedButton(
            onPressed: _isProcessing ? null : _confirmPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F1413),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Kích Hoạt Dùng Thử 7 Ngày (0đ)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Có thể hủy bất cứ lúc nào trong Cài đặt Apple ID trước ngày gia hạn.',
              style: TextStyle(fontSize: 11, color: AppColors.iceTextMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem(int index, String title, IconData icon, String subtitle) {
    final isSelected = _selectedMethod == index;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.iceOlive.withValues(alpha: 0.08) : AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.iceOlive : AppColors.iceCardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.iceOlive : AppColors.iceTextSlate, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: AppColors.iceTextNavy)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.iceTextSlate)),
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
