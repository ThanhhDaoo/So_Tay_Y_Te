import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../viewmodel/profile_state.dart';

class ProfileFamilySwitcher extends StatelessWidget {
  final List<FamilyMemberChip> members;
  final String selectedMemberId;
  final ValueChanged<String> onSelectMember;
  final VoidCallback? onAddMemberTap;
  final VoidCallback? onVaultProTap;

  const ProfileFamilySwitcher({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onSelectMember,
    this.onAddMemberTap,
    this.onVaultProTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_prof_family_group.svg',
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      AppColors.iceTextMuted,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'HỒ SƠ GIA ĐÌNH',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: AppColors.iceTextMuted,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onVaultProTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF8E7D3),
                          Color(0xFFE8D2B5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFD8C2A3),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F433624),
                          blurRadius: 4,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_prof_vault_pro.svg',
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF433624),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Gói Vault Pro',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: const Color(0xFF433624),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          'assets/icons/ic_prof_arrow_right.svg',
                          width: 8,
                          height: 8,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF433624),
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: members.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == members.length) {
                return _AddMemberChip(onTap: onAddMemberTap);
              }
              final member = members[index];
              final isSelected = member.id == selectedMemberId;
              return _FamilyChipItem(
                member: member,
                isSelected: isSelected,
                onTap: () => onSelectMember(member.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FamilyChipItem extends StatelessWidget {
  const _FamilyChipItem({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final FamilyMemberChip member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF2EADA) : AppColors.surfaceCream,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.iceAccentCream
                  : AppColors.iceCardBorder.withValues(alpha: 0.70),
              width: 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5C6254)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        member.avatarAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C6254),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceLight,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/ic_prof_check_small.svg',
                            width: 8,
                            height: 8,
                            colorFilter: const ColorFilter.mode(
                              AppColors.surfaceLight,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 9),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: AppTypography.labelSemiBold.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.iceTextNavy,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.subtitle,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.iceTextBrownDark
                          : AppColors.iceTextMuted,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMemberChip extends StatelessWidget {
  const _AddMemberChip({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x99DCE9FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5DFD4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/ic_prof_add_member.svg',
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF5C6254),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Thêm',
                style: AppTypography.labelSemiBold.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5C6254),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
