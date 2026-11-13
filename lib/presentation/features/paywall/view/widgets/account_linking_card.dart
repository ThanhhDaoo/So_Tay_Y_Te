import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class AccountLinkingCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECE7DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_vault_account_link.svg',
                width: 17,
                height: 17,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF4E5547),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Liên Kết Tài Khoản Bảo Mật',
                style: AppTypography.heading3.copyWith(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Liên kết tài khoản để kích hoạt sao lưu tức thời dữ liệu offline hiện tại và tránh thất lạc khi đổi thiết bị.',
            style: AppTypography.body.copyWith(
              fontSize: 12,
              color: const Color(0xFF3D4947),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SocialLinkButton(
                  iconAsset: 'assets/icons/ic_vault_google.svg',
                  label: linkedProvider == 'Google' ? 'Đã kết nối' : 'Google',
                  isLinked: linkedProvider == 'Google',
                  onTap: onLinkGoogle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SocialLinkButton(
                  iconAsset: 'assets/icons/ic_vault_apple.svg',
                  label: linkedProvider == 'Apple' ? 'Đã kết nối' : 'Apple ID',
                  isLinked: linkedProvider == 'Apple',
                  onTap: onLinkApple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: const Color(0xFFF7F5EF),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onLinkPhone,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E0D6)),
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
                        Color(0xFF4E5547),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      linkedProvider == 'Phone'
                          ? 'Đã xác thực OTP (+84)'
                          : 'Sử dụng Số Điện Thoại (SMS OTP)',
                      style: AppTypography.labelSemiBold.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_vault_iso_shield.svg',
                width: 11,
                height: 13,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF6D7A77),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tuân thủ tiêu chuẩn bảo mật dữ liệu y tế ISO 27799',
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6D7A77),
                ),
              ),
            ],
          ),
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
      color: isLinked ? const Color(0xFFE5EEFF) : const Color(0xFFF7F5EF),
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
                  ? const Color(0xFF00685F)
                  : const Color(0xFFE5E0D6),
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
                      ? const Color(0xFF00685F)
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
