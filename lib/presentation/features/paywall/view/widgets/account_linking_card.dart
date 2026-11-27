import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../common_widgets/layout/app_layout.dart';

class AccountLinkingCard extends StatefulWidget {
  const AccountLinkingCard({
    super.key,
    required this.onLinkGoogle,
    required this.onLinkApple,
    required this.onLinkPhone,
    this.linkedProvider,
  });

  final VoidCallback onLinkGoogle;
  final VoidCallback onLinkApple;
  final VoidCallback onLinkPhone;
  final String? linkedProvider;

  @override
  State<AccountLinkingCard> createState() => _AccountLinkingCardState();
}

class _AccountLinkingCardState extends State<AccountLinkingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final linked = widget.linkedProvider;
    final hasLinked = linked != null && linked.isNotEmpty;

    return CleanCard(
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFEAECF0),
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppLayoutTokens.innerRadius),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.circular(AppLayoutTokens.innerRadius),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_vault_account_link.svg',
                      width: 17,
                      height: 17,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1E56A0),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liên Kết Tài Khoản Bảo Mật',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.heading3.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLinked
                            ? 'Đã kết nối $linked • Sao lưu tự động'
                            : 'Sao lưu hồ sơ offline khi đổi thiết bị',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 12,
                          color: hasLinked
                              ? const Color(0xFF0E9F6E)
                              : const Color(0xFF475467),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF1E56A0),
                  size: 22,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SocialLinkButton(
                    iconAsset: 'assets/icons/ic_vault_google.svg',
                    label: linked == 'Google' ? 'Đã kết nối' : 'Google',
                    isLinked: linked == 'Google',
                    onTap: widget.onLinkGoogle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SocialLinkButton(
                    iconAsset: 'assets/icons/ic_vault_apple.svg',
                    label: linked == 'Apple' ? 'Đã kết nối' : 'Apple ID',
                    isLinked: linked == 'Apple',
                    onTap: widget.onLinkApple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppLayoutTokens.innerRadius),
              child: InkWell(
                onTap: widget.onLinkPhone,
                borderRadius:
                    BorderRadius.circular(AppLayoutTokens.innerRadius),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppLayoutTokens.innerRadius),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_vault_phone.svg',
                        width: 12,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF1E56A0),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          linked == 'Phone'
                              ? 'Đã xác thực OTP (+84)'
                              : 'Sử dụng Số Điện Thoại (SMS OTP)',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSemiBold.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_vault_iso_shield.svg',
                  width: 11,
                  height: 13,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF667085),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tuân thủ tiêu chuẩn bảo mật dữ liệu y tế ISO 27799',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialLinkButton extends StatelessWidget {
  const _SocialLinkButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.isLinked = false,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final bool isLinked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLinked ? const Color(0xFFE5EEFF) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLinked
                  ? const Color(0xFF0E9F6E)
                  : const Color(0xFFEAECF0),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelSemiBold.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isLinked
                      ? const Color(0xFF0E9F6E)
                      : AppColors.iceTextNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
