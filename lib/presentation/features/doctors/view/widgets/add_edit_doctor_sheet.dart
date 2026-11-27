import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/ocr_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/doctor_contact.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

class AddEditDoctorSheet extends StatefulWidget {
  final DoctorContact? existing;
  final Future<void> Function({
    String? existingId,
    required String fullName,
    required String specialty,
    required String hospitalName,
    required String phoneNumber,
    String? avatarPath,
    String? lastVisitDate,
    String? lastVisitNote,
    bool isPrimaryDoctor,
  }) onSave;

  const AddEditDoctorSheet({
    super.key,
    this.existing,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    DoctorContact? existing,
    required Future<void> Function({
      String? existingId,
      required String fullName,
      required String specialty,
      required String hospitalName,
      required String phoneNumber,
      String? avatarPath,
      String? lastVisitDate,
      String? lastVisitNote,
      bool isPrimaryDoctor,
    }) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditDoctorSheet(
        existing: existing,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditDoctorSheet> createState() => _AddEditDoctorSheetState();
}

class _AddEditDoctorSheetState extends State<AddEditDoctorSheet> {
  static const List<String> _specialtyPresets = [
    'Tim mạch & Huyết áp',
    'Cơ xương khớp',
    'Nội tiết & Tiểu đường',
    'Tiêu hóa - Gan mật',
    'Thần kinh & Giấc ngủ',
    'Nội tổng quát',
  ];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _specialtyCtrl;
  late final TextEditingController _hospitalCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _noteCtrl;
  String? _avatarPath;
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    final defaultDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _nameCtrl = TextEditingController(text: e?.fullName ?? '');
    _specialtyCtrl =
        TextEditingController(text: e?.specialty ?? 'Tim mạch & Huyết áp');
    _hospitalCtrl = TextEditingController(text: e?.hospitalName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phoneNumber ?? '');
    _dateCtrl = TextEditingController(text: e?.lastVisitDate ?? defaultDate);
    _noteCtrl = TextEditingController(text: e?.lastVisitNote ?? '');
    _avatarPath = e?.avatarPath;
    _isPrimary = e?.isPrimaryDoctor ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    _hospitalCtrl.dispose();
    _phoneCtrl.dispose();
    _dateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDoctorAvatar() async {
    final ocr = sl.isRegistered<OcrService>() ? sl<OcrService>() : OcrServiceImpl();
    final picked = await ocr.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _avatarPath = picked);
    }
  }

  Widget _buildAvatarPreview() {
    ImageProvider? img;
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (_avatarPath!.startsWith('assets/')) {
        img = AssetImage(_avatarPath!);
      } else if (File(_avatarPath!).existsSync()) {
        img = FileImage(File(_avatarPath!));
      }
    }
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceCream,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            image: img != null
                ? DecorationImage(image: img, fit: BoxFit.cover)
                : null,
          ),
          child: img == null
              ? const Icon(
                  Icons.medical_services_rounded,
                  size: 34,
                  color: AppColors.primary,
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SeniorActionButton(
            label: 'Chọn ảnh đại diện bác sĩ',
            icon: Icons.photo_library_rounded,
            variant: SeniorButtonVariant.secondaryOutline,
            onPressed: _pickDoctorAvatar,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
                  Icons.person_add_alt_1_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.existing != null
                        ? 'Cập Nhật Thông Tin Bác Sĩ'
                        : 'Thêm Bác Sĩ Đã Khám',
                    style: const TextStyle(
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

            _buildAvatarPreview(),
            const SizedBox(height: 16),

            _SeniorField(
              controller: _nameCtrl,
              label: 'Họ tên bác sĩ (Bắt buộc) *',
              hint: 'VD: PGS.TS.BS Nguyễn Văn An',
              icon: Icons.badge_rounded,
            ),
            const SizedBox(height: 14),

            const Text(
              'Chọn nhanh chuyên khoa:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextSlate,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialtyPresets.map((sp) {
                final active = _specialtyCtrl.text.trim() == sp;
                return ChoiceChip(
                  selected: active,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _specialtyCtrl.text = sp),
                  label: Text(
                    sp,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.iceTextNavy,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            _SeniorField(
              controller: _specialtyCtrl,
              label: 'Chuyên khoa *',
              hint: 'VD: Nội Tim mạch',
              icon: Icons.local_hospital_rounded,
            ),
            const SizedBox(height: 14),

            _SeniorField(
              controller: _hospitalCtrl,
              label: 'Bệnh viện / Phòng khám *',
              hint: 'VD: Bệnh viện Đại học Y Dược',
              icon: Icons.apartment_rounded,
            ),
            const SizedBox(height: 14),

            _SeniorField(
              controller: _phoneCtrl,
              label: 'Số điện thoại liên hệ *',
              hint: 'VD: 0903 128 456',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            _SeniorField(
              controller: _dateCtrl,
              label: 'Ngày khám gần nhất',
              hint: 'VD: 15/10/2026',
              icon: Icons.event_rounded,
            ),
            const SizedBox(height: 14),

            _SeniorField(
              controller: _noteCtrl,
              label: 'Ghi chú lần khám gần nhất',
              hint: 'VD: Hẹn tái khám sau 3 tháng, duy trì thuốc huyết áp...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Đặt làm Bác sĩ theo dõi chính',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              value: _isPrimary,
              activeThumbColor: SeniorTokens.callActionGreen,
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
            const SizedBox(height: 12),

            SeniorActionButton(
              label: 'Lưu vào danh bạ bác sĩ',
              icon: Icons.check_circle_rounded,
              variant: SeniorButtonVariant.callNow,
              minHeight: 56,
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty ||
                    _phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vui lòng nhập đầy đủ Họ tên và Số điện thoại bác sĩ.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await widget.onSave(
                  existingId: widget.existing?.id,
                  fullName: _nameCtrl.text,
                  specialty: _specialtyCtrl.text.trim().isEmpty
                      ? 'Nội tổng quát'
                      : _specialtyCtrl.text,
                  hospitalName: _hospitalCtrl.text.trim().isEmpty
                      ? 'Phòng khám chuyên khoa'
                      : _hospitalCtrl.text,
                  phoneNumber: _phoneCtrl.text,
                  avatarPath: _avatarPath,
                  lastVisitDate: _dateCtrl.text,
                  lastVisitNote: _noteCtrl.text,
                  isPrimaryDoctor: _isPrimary,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeniorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SeniorField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 16),
        prefixIcon: Icon(icon, size: 26, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
