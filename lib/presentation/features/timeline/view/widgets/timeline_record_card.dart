import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/layout/app_layout.dart';
import '../../viewmodel/timeline_state.dart';

/// Thẻ hiển thị một đợt khám / tiêm chủng trên trục Dòng Thời Gian Bệnh Án.
/// Tuân thủ Quy tắc 3 điểm dữ liệu (3-Point Rule):
/// 1. Thời gian & Trạng thái (Header)
/// 2. Tên đợt khám / Chẩn đoán chính & Cơ sở y tế (Visual Anchor, không lồng hộp)
/// 3. Dải chỉ báo nhanh (Toa thuốc / Tài liệu / Tóm tắt nhanh) — đẩy chi tiết dài sang BottomSheet & Trang Chi tiết.
class TimelineRecordCard extends StatelessWidget {
  final TimelineRecordItem record;
  final VoidCallback onOpenDetail;
  final VoidCallback? onViewPrescription;
  final VoidCallback? onViewAllDocs;

  const TimelineRecordCard({
    super.key,
    required this.record,
    required this.onOpenDetail,
    this.onViewPrescription,
    this.onViewAllDocs,
  });

  bool get _hasSecondaryDetails =>
      (record.diagnosis != null &&
          (record.diagnosis!.description?.trim().isNotEmpty ?? false)) ||
      record.attachedDocs.isNotEmpty ||
      record.prescription != null ||
      record.vaccines.isNotEmpty ||
      record.hospitalFee != null;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CleanCard(
          onTap: onOpenDetail,
          padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Điểm 1: Thời gian + Trạng thái đợt khám
              _buildDateAndStatusRow(),
              const SizedBox(height: 10),

              // Điểm 2: Tiêu đề đợt khám (chữ đậm nổi bật) + Cơ sở khám mảnh gọn 1 dòng
              Text(
                record.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.iceTextNavy,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              _buildFacilityLine(),

              if (record.diagnosis != null &&
                  record.diagnosis!.title.trim().isNotEmpty &&
                  record.diagnosis!.title.trim() != record.title.trim()) ...[
                const SizedBox(height: 8),
                Text(
                  record.diagnosis!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextSlate,
                    height: 1.35,
                  ),
                ),
              ],

              // Điểm 3: Dải chip tóm tắt & hành động nhanh (Progressive Disclosure)
              const SizedBox(height: 12),
              _buildCompactFooter(context),
            ],
          ),
        ),
        Positioned(
          left: -21,
          top: 20,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.timelineCardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: record.spineDotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndStatusRow() {
    final (badgeBg, badgeText) = switch (record.statusStyle) {
      TimelineStatusStyle.highlightCream => (
        AppColors.iceAccentCream,
        AppColors.timelineBadgeBrown,
      ),
      TimelineStatusStyle.neutralSoft => (
        AppColors.timelineInputBg,
        AppColors.iceTextSlate,
      ),
      TimelineStatusStyle.mutedChip => (
        AppColors.timelineChipBg,
        AppColors.iceTextSlate,
      ),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            record.dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: record.statusStyle == TimelineStatusStyle.highlightCream
                  ? AppColors.timelineOlive
                  : AppColors.timelineTextWarm,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            record.statusLabel,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: badgeText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityLine() {
    final hasSubtitle = record.facilitySubtitle.trim().isNotEmpty;
    final displayText = hasSubtitle
        ? '${record.facilityName} • ${record.facilitySubtitle}'
        : record.facilityName;

    return Row(
      children: [
        SvgPicture.asset(
          record.facilityIconAsset,
          width: 18,
          height: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            displayText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: AppColors.iceTextSlate,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFooter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (record.prescription != null)
                _CompactMetaPill(
                  icon: Icons.medication_outlined,
                  label: 'Toa thuốc',
                  onTap: onViewPrescription ?? onOpenDetail,
                ),
              if (record.attachedDocs.isNotEmpty)
                _CompactMetaPill(
                  icon: Icons.attach_file_rounded,
                  label: '${record.attachedDocs.length} tài liệu',
                  onTap: onViewAllDocs ?? onOpenDetail,
                ),
              if (record.vaccines.isNotEmpty)
                _CompactMetaPill(
                  icon: Icons.vaccines_outlined,
                  label: '${record.vaccines.length} mũi tiêm',
                  onTap: () => _showQuickSummarySheet(context),
                ),
              if (_hasSecondaryDetails &&
                  record.prescription == null &&
                  record.attachedDocs.isEmpty &&
                  record.vaccines.isEmpty)
                _CompactMetaPill(
                  icon: Icons.notes_rounded,
                  label: 'Tóm tắt nhanh',
                  onTap: () => _showQuickSummarySheet(context),
                ),
            ],
          ),
        ),
        if (_hasSecondaryDetails &&
            (record.prescription != null ||
                record.attachedDocs.isNotEmpty ||
                record.hospitalFee != null))
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () => _showQuickSummarySheet(context),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Xem nhanh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chi tiết',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.timelineOlive,
              ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              'assets/icons/ic_arrow_right_small.svg',
              width: 5,
              height: 8.5,
            ),
          ],
        ),
      ],
    );
  }

  /// BottomSheet xem nhanh toàn bộ dữ liệu phụ của đợt khám (Progressive Disclosure)
  /// đảm bảo giữ nguyên 100% thông tin (triệu chứng, viện phí, vắc xin, ảnh đính kèm, toa thuốc).
  void _showQuickSummarySheet(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
        ),
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          12,
          AppLayoutTokens.screenPadding,
          bottomPadding + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.iceBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.iceCardBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.dateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.timelineOlive,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CleanCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KeyValueRow(
                            label: 'Cơ sở y tế',
                            value: record.facilityName,
                          ),
                          if (record.facilitySubtitle.trim().isNotEmpty)
                            KeyValueRow(
                              label: 'Khoa / Bác sĩ',
                              value: record.facilitySubtitle,
                            ),
                          KeyValueRow(
                            label: 'Trạng thái',
                            value: record.statusLabel,
                          ),
                          if (record.hospitalFee != null)
                            KeyValueRow(
                              label: 'Viện phí',
                              value: record.hospitalFee!,
                              valueWeight: FontWeight.w700,
                            ),
                        ],
                      ),
                    ),
                    if (record.diagnosis != null) ...[
                      const SizedBox(height: 16),
                      CleanCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.diagnosis!.sectionTitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppColors.iceTextMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              record.diagnosis!.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.iceTextNavy,
                              ),
                            ),
                            if (record.diagnosis!.description != null &&
                                record.diagnosis!.description!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                record.diagnosis!.description!,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.45,
                                  color: AppColors.iceTextSlate,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (record.prescription != null) ...[
                      const SizedBox(height: 16),
                      CleanCard(
                        onTap: () {
                          Navigator.pop(ctx);
                          (onViewPrescription ?? onOpenDetail)();
                        },
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/ic_prescription_pill.svg',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.prescription!.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.iceTextNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    record.prescription!.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.iceTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Xem toa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.timelineOlive,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (record.vaccines.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      CleanCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VẮC XIN ĐÃ TIÊM',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppColors.iceTextMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (int i = 0; i < record.vaccines.length; i++) ...[
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_vaccine_shield.svg',
                                    width: 14,
                                    height: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      record.vaccines[i],
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.iceTextNavy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (i < record.vaccines.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (record.attachedDocs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      CleanCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TÀI LIỆU ĐÍNH KÈM (${record.attachedDocs.length})',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: AppColors.iceTextMuted,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    (onViewAllDocs ?? onOpenDetail)();
                                  },
                                  child: const Text(
                                    'Mở kho tài liệu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.timelineOlive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 88,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: record.attachedDocs.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final doc = record.attachedDocs[index];
                                  return SizedBox(
                                    width: 112,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            height: 64,
                                            width: 112,
                                            color: AppColors.timelineInputBg,
                                            child: _buildDocImage(
                                              doc.imageAsset,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doc.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.iceTextNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.timelineOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onOpenDetail();
                },
                child: const Text(
                  'Mở Hồ Sơ Bệnh Án Đầy Đủ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return const Center(
      child: Icon(
        Icons.description_outlined,
        color: AppColors.iceOlive,
        size: 24,
      ),
    );
  }
}

class _CompactMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactMetaPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.timelineInputBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13.5,
                color: AppColors.timelineOlive,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
