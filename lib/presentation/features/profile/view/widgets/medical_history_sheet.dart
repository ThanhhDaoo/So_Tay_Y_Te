import 'package:flutter/material.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/medical_event.dart';
import '../../../../../domain/repositories/medical_record_repository.dart';

class MedicalHistorySheet extends StatefulWidget {
  final String patientName;
  final List<String> chronicConditions;

  const MedicalHistorySheet({
    super.key,
    required this.patientName,
    this.chronicConditions = const [],
  });

  static void show(
    BuildContext context, {
    required String patientName,
    List<String> chronicConditions = const [],
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicalHistorySheet(
        patientName: patientName,
        chronicConditions: chronicConditions,
      ),
    );
  }

  @override
  State<MedicalHistorySheet> createState() => _MedicalHistorySheetState();
}

class _MedicalHistorySheetState extends State<MedicalHistorySheet> {
  List<MedicalEvent> _events = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      if (sl.isRegistered<MedicalRecordRepository>()) {
        final loaded = await sl<MedicalRecordRepository>().getMedicalTimeline();
        if (mounted) {
          setState(() {
            _events = loaded;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final hasHistory = _events.isNotEmpty || widget.chronicConditions.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.history_edu, color: AppColors.iceOlive, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bệnh Sử Chi Tiết: ${widget.patientName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.iceTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.iceCardBorder),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.iceOlive))
                : !hasHistory
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(20, 32, 20, 24 + bottomPadding),
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.iceOlive.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.history_edu_outlined,
                                    size: 36,
                                    color: AppColors.iceOlive,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Chưa Có Tiền Sử Bệnh Án',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.iceTextNavy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Hồ sơ của bạn chưa có lịch sử bệnh án hoặc phẫu thuật nào được ghi nhận trước đây.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.iceTextSlate,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
                        children: [
                          if (widget.chronicConditions.isNotEmpty) ...[
                            const Text(
                              'BỆNH NỀN MÃN TÍNH ĐANG THEO DÕI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.iceOlive,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.chronicConditions
                                  .map(
                                    (c) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWarm,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.iceCardBorder),
                                      ),
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.iceTextNavy,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (_events.isNotEmpty) ...[
                            Text(
                              'LỊCH SỬ KHÁM & ĐIỀU TRỊ (${_events.length} ĐỢT)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.iceOlive,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (final e in _events)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.iceCardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${e.date.day.toString().padLeft(2, "0")}/${e.date.month.toString().padLeft(2, "0")}/${e.date.year}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.iceOlive,
                                          ),
                                        ),
                                        if (e.department != null && e.department!.isNotEmpty)
                                          Text(
                                            e.department!,
                                            style: const TextStyle(fontSize: 11, color: AppColors.iceTextMuted),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.diagnosis?.isNotEmpty == true ? e.diagnosis! : e.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.iceTextNavy,
                                      ),
                                    ),
                                    if (e.facilityName != null && e.facilityName!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${e.facilityName}${e.doctorName != null && e.doctorName!.isNotEmpty ? " • BS. ${e.doctorName}" : ""}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
