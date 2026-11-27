import 'package:flutter/material.dart';
import '../../../../../core/services/user_session_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../../../routes/app_routes.dart';
import '../../viewmodel/paywall_state.dart';

class VaultProActiveDashboard extends StatelessWidget {
  const VaultProActiveDashboard({
    super.key,
    required this.state,
    required this.onChangePlanTap,
    required this.onResetForTesting,
  });

  final PaywallState state;
  final VoidCallback onChangePlanTap;
  final VoidCallback onResetForTesting;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Hôm nay';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final plan = state.activePlan ?? state.selectedPlan;
    final holderName = AppSessionNotifier.instance.fullName?.trim();
    final displayHolder = (holderName != null && holderName.isNotEmpty)
        ? holderName
        : 'Chủ Sổ Tay Y Tế';
    final expiryText = plan == PlanType.lifetime
        ? 'Vĩnh viễn (Trọn đời)'
        : _formatDate(state.expiresAt ?? DateTime.now().add(const Duration(days: 365)));
    final activatedText = _formatDate(state.activatedAt ?? DateTime.now());
    final txCode = state.transactionCode ?? 'VP-ACTIVE-PRO';
    final method = state.paymentMethod ?? 'Apple Pay (Sandbox)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Luxury VIP Membership Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF163E75),
                Color(0xFF1E56A0),
                Color(0xFF1E56A0),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8B278), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F1E56A0),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFFFFFF)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Color(0xFFFFFFFF),
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'VAULT PRO • ĐANG HOẠT ĐỘNG',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD580),
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                plan.title,
                style: AppTypography.heading1.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chủ thẻ: $displayHolder',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE6D5B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hiệu lực đến',
                          style: TextStyle(
                            color: Color(0xFFCBBBA0),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expiryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showTransactionDetailSheet(
                      context,
                      planTitle: plan.title,
                      holder: displayHolder,
                      txCode: txCode,
                      method: method,
                      activatedText: activatedText,
                      expiryText: expiryText,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFFFFF),
                      backgroundColor: Colors.black.withValues(alpha: 0.22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 14),
                    label: const Text(
                      'Biên lai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppLayoutTokens.sectionGap),

        // Unlocked Pro Features Hub
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAECF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '5 Đặc Quyền Đã Mở Khóa',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.heading3.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '5/5 ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Chạm vào từng tính năng bên dưới để trải nghiệm ngay:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.iceTextSlate,
                ),
              ),
              const SizedBox(height: 14),
              _UnlockedPerkTile(
                icon: Icons.family_restroom_rounded,
                title: 'Đa hồ sơ gia đình không giới hạn',
                subtitle: 'Quản lý hồ sơ bố mẹ, con nhỏ trên cùng tài khoản',
                onTap: () => Navigator.of(context).pushReplacementNamed(
                  AppRoutes.profile,
                ),
              ),
              _UnlockedPerkTile(
                icon: Icons.document_scanner_rounded,
                title: 'AI Medical OCR không giới hạn',
                subtitle: 'Quét tự động đơn thuốc & phiếu xét nghiệm',
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.documents,
                ),
              ),
              _UnlockedPerkTile(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Xuất Bệnh án PDF A4 chuẩn y khoa',
                subtitle: 'In hoặc gửi báo cáo sinh hiệu cho bác sĩ',
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.vitalReports,
                ),
              ),
              _UnlockedPerkTile(
                icon: Icons.cloud_done_rounded,
                title: 'Đồng bộ đám mây 2 chiều & Sao lưu AES-256',
                subtitle: 'Tự động đồng bộ Supabase & xuất file mã hóa',
                onTap: () => Navigator.of(context).pushReplacementNamed(
                  AppRoutes.securitySettings,
                ),
              ),
              _UnlockedPerkTile(
                icon: Icons.medical_information_rounded,
                title: 'Thẻ Y Tế Khẩn Cấp ICE & Mã QR Bác Sĩ',
                subtitle: 'Truy cập nhanh nhóm máu, dị ứng khi cấp cứu',
                isLast: true,
                onTap: () => Navigator.of(context).pushReplacementNamed(
                  AppRoutes.emergencyCard,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Plan Management & Test Reset Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE8FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, size: 18, color: Color(0xFF1E56A0)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Quản Lý Gói & Công Cụ Kiểm Thử',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Bạn có thể thử chuyển đổi sang gói khác hoặc reset lại về Gói Free để kiểm thử lại luồng thanh toán từ đầu.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFF6B5840),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isProcessing ? null : onChangePlanTap,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: const Text(
                        'Đổi gói khác',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E56A0),
                        side: const BorderSide(color: Color(0xFFC7A87E)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isProcessing ? null : onResetForTesting,
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text(
                        'Reset về Free',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTransactionDetailSheet(
    BuildContext context, {
    required String planTitle,
    required String holder,
    required String txCode,
    required String method,
    required String activatedText,
    required String expiryText,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D3C8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chi tiết gói đăng ký Vault Pro',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                const SizedBox(height: 16),
                KeyValueRow(label: 'Gói kích hoạt', value: planTitle),
                const SizedBox(height: 12),
                KeyValueRow(label: 'Chủ thẻ', value: holder),
                const SizedBox(height: 12),
                KeyValueRow(label: 'Mã giao dịch', value: txCode),
                const SizedBox(height: 12),
                KeyValueRow(label: 'Phương thức', value: method),
                const SizedBox(height: 12),
                KeyValueRow(label: 'Ngày kích hoạt', value: activatedText),
                const SizedBox(height: 12),
                KeyValueRow(
                  label: 'Hiệu lực đến',
                  value: expiryText,
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UnlockedPerkTile extends StatelessWidget {
  const _UnlockedPerkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppLayoutTokens.itemGap),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.iceTextSlate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.iceTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
