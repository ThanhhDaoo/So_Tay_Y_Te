import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/daily_vital_log.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Bảng nhập chỉ số huyết áp thủ công cỡ chữ lớn (28px - 30px) với nút [-] [+].
class ManualBloodPressureSheet extends StatefulWidget {
  final int initialSystolic;
  final int initialDiastolic;
  final int initialPulse;
  final Future<void> Function(int sys, int dia, int pulse, String? note) onSave;

  const ManualBloodPressureSheet({
    super.key,
    this.initialSystolic = 124,
    this.initialDiastolic = 80,
    this.initialPulse = 72,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    DailyVitalLog? previousLog,
    required Future<void> Function(int sys, int dia, int pulse, String? note) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualBloodPressureSheet(
        initialSystolic: previousLog?.systolic ?? 124,
        initialDiastolic: previousLog?.diastolic ?? 80,
        initialPulse: previousLog?.heartRate ?? 72,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ManualBloodPressureSheet> createState() => _ManualBloodPressureSheetState();
}

class _ManualBloodPressureSheetState extends State<ManualBloodPressureSheet> {
  late int _sys;
  late int _dia;
  late int _pulse;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sys = widget.initialSystolic;
    _dia = widget.initialDiastolic;
    _pulse = widget.initialPulse;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final eval = DailyVitalLog(
      id: 'preview',
      dateKey: '',
      measuredAt: DateTime.now(),
      systolic: _sys,
      diastolic: _dia,
      heartRate: _pulse,
      statusLevel: DailyVitalLog.evaluateLevel(_sys, _dia),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFC62828),
                  size: 30,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Cập Nhật Huyết Áp Hôm Nay',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ),
                SeniorLabeledIconButton(
                  icon: Icons.close_rounded,
                  label: 'Đóng',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SeniorNumberStepperField(
              label: 'Số trên • Tâm thu (SYS)',
              unit: 'mmHg',
              value: _sys,
              min: 70,
              max: 250,
              accentColor: const Color(0xFFB71C1C),
              onChanged: (v) => setState(() => _sys = v),
            ),
            const SizedBox(height: 14),
            SeniorNumberStepperField(
              label: 'Số dưới • Tâm trương (DIA)',
              unit: 'mmHg',
              value: _dia,
              min: 40,
              max: 150,
              accentColor: AppColors.primary,
              onChanged: (v) => setState(() => _dia = v),
            ),
            const SizedBox(height: 14),
            SeniorNumberStepperField(
              label: 'Nhịp tim (PULSE)',
              unit: 'nhịp/phút',
              value: _pulse,
              min: 35,
              max: 190,
              accentColor: AppColors.accent,
              onChanged: (v) => setState(() => _pulse = v),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SeniorTokens.callActionGreenSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Đánh giá nhanh: ${eval.statusLabelVi} — ${eval.seniorAdviceVi}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceTextNavy,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _noteCtrl,
              style: const TextStyle(fontSize: 16.5),
              decoration: InputDecoration(
                labelText: 'Ghi chú thêm (VD: Đo buổi sáng trước ăn)',
                labelStyle: const TextStyle(fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            SeniorActionButton(
              label: 'Lưu vào hệ thống ($_sys/$_dia mmHg)',
              icon: Icons.check_circle_rounded,
              variant: SeniorButtonVariant.callNow,
              minHeight: 56,
              onPressed: () async {
                if (_sys <= _dia) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Số trên (Tâm thu) cần lớn hơn số dưới (Tâm trương).',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                  return;
                }
                final note = _noteCtrl.text.trim().isEmpty
                    ? null
                    : _noteCtrl.text.trim();
                Navigator.pop(context);
                await widget.onSave(_sys, _dia, _pulse, note);
              },
            ),
          ],
        ),
      ),
    );
  }
}
