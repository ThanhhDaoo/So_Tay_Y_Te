import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../viewmodel/timeline_state.dart';

/// Thẻ hiển thị một đợt khám / tiêm chủng trên trục Dòng Thời Gian Bệnh Án.
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.iceCardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.iceTextNavy.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildFacilityBox(),
              if (record.diagnosis != null) ...[
                const SizedBox(height: 10),
                _buildDiagnosisSection(record.diagnosis!),
              ],
              if (record.attachedDocs.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildAttachedDocsSection(),
              ],
              if (record.prescription != null) ...[
                const SizedBox(height: 10),
                _buildPrescriptionCard(record.prescription!),
              ],
              if (record.vaccines.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildVaccinesList(),
              ],
              if (record.hospitalFee != null) ...[
                const SizedBox(height: 10),
                _buildCostFooter(),
              ],
            ],
          ),
        ),
        Positioned(
          left: -21,
          top: 16,
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

  Widget _buildHeader() {
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.dateLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.275,
                  color: record.statusStyle == TimelineStatusStyle.highlightCream
                      ? AppColors.timelineOlive
                      : AppColors.timelineTextWarm,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                record.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            record.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
              color: badgeText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.timelineInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            record.facilityIconAsset,
            width: 15,
            height: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.facilityName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                Text(
                  record.facilitySubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisSection(TimelineDiagnosisBlock diagnosis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diagnosis.sectionTitle,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
            color: AppColors.iceTextMuted,
          ),
        ),
        const SizedBox(height: 4),
        if (diagnosis.isBoxed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.timelineInputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SvgPicture.asset(
                    'assets/icons/ic_diagnosis_note.svg',
                    width: 13.33,
                    height: 18.67,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diagnosis.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                      if (diagnosis.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          diagnosis.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.iceTextSlate,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            diagnosis.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: AppColors.iceTextNavy,
            ),
          ),
      ],
    );
  }

  Widget _buildAttachedDocsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hồ sơ kết quả đính kèm (${record.attachedDocs.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.44,
                color: AppColors.iceTextSlate,
              ),
            ),
            InkWell(
              onTap: onViewAllDocs ?? onOpenDetail,
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  color: AppColors.timelineOlive,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 0; i < record.attachedDocs.length; i++) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.timelineChipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          color: AppColors.timelineCardBg,
                          child: Image.asset(
                            record.attachedDocs[i].imageAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.attachedDocs[i].title,
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
                ),
              ),
              if (i < record.attachedDocs.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPrescriptionCard(TimelinePrescriptionSummary rx) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.timelineInputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_prescription_pill.svg',
            width: 16.67,
            height: 18.33,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rx.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rx.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.iceTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onViewPrescription ?? onOpenDetail,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.timelineCardBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Xem toa',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.timelineOlive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < record.vaccines.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.timelineChipBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_vaccine_shield.svg',
                  width: 13.33,
                  height: 13.33,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    record.vaccines[i],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i < record.vaccines.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildCostFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.timelineDividerBlue, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Viện phí: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.iceTextSlate,
                ),
              ),
              Text(
                record.hospitalFee!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.24,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onOpenDetail,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.timelineChipBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chi tiết đợt khám',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.timelineOlive,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    'assets/icons/ic_arrow_right_small.svg',
                    width: 4.93,
                    height: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

