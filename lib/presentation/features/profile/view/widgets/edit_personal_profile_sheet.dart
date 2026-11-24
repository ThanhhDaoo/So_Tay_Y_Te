import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/input_validators.dart';
import '../../../../../core/widgets/safe_avatar_image.dart';

class EditPersonalProfileSheet extends StatefulWidget {
  final String initialFullName;
  final String? initialDob;
  final String? initialGender;
  final String? initialBloodType;
  final String? initialHeight;
  final String? initialWeight;
  final String? initialEmergencyContact;
  final String? initialAllergies;
  final String? initialChronicConditions;
  final String? initialOrganDonor;
  final String? initialRegion;
  final String? initialAvatarUrl;
  final String? sheetTitle;
  final VoidCallback? onPickAvatar;
  final Future<void> Function(String newAvatarPath)? onAvatarChanged;
  final Future<void> Function({
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? height,
    String? weight,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
    String? organDonor,
    String? region,
    String? avatarUrl,
  }) onSave;

  const EditPersonalProfileSheet({
    super.key,
    this.sheetTitle,
    required this.initialFullName,
    this.initialDob,
    this.initialGender,
    this.initialBloodType,
    this.initialHeight,
    this.initialWeight,
    this.initialEmergencyContact,
    this.initialAllergies,
    this.initialChronicConditions,
    this.initialOrganDonor,
    this.initialRegion,
    this.initialAvatarUrl,
    this.onPickAvatar,
    this.onAvatarChanged,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    String? sheetTitle,
    required String initialFullName,
    String? initialDob,
    String? initialGender,
    String? initialBloodType,
    String? initialHeight,
    String? initialWeight,
    String? initialEmergencyContact,
    String? initialAllergies,
    String? initialChronicConditions,
    String? initialOrganDonor,
    String? initialRegion,
    String? initialAvatarUrl,
    VoidCallback? onPickAvatar,
    Future<void> Function(String newAvatarPath)? onAvatarChanged,
    required Future<void> Function({
      required String fullName,
      String? dateOfBirth,
      String? gender,
      String? bloodType,
      String? height,
      String? weight,
      String? emergencyContact,
      String? allergies,
      String? chronicConditions,
      String? organDonor,
      String? region,
      String? avatarUrl,
    }) onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPersonalProfileSheet(
        sheetTitle: sheetTitle,
        initialFullName: initialFullName,
        initialDob: initialDob,
        initialGender: initialGender,
        initialBloodType: initialBloodType,
        initialHeight: initialHeight,
        initialWeight: initialWeight,
        initialEmergencyContact: initialEmergencyContact,
        initialAllergies: initialAllergies,
        initialChronicConditions: initialChronicConditions,
        initialOrganDonor: initialOrganDonor,
        initialRegion: initialRegion,
        initialAvatarUrl: initialAvatarUrl,
        onPickAvatar: onPickAvatar,
        onAvatarChanged: onAvatarChanged,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditPersonalProfileSheet> createState() => _EditPersonalProfileSheetState();
}

class _EditPersonalProfileSheetState extends State<EditPersonalProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _iceContactCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _conditionsCtrl;
  late final TextEditingController _regionCtrl;

  late String _gender;
  late String _bloodType;
  DateTime? _selectedDob;
  late String _organDonor;
  String? _currentAvatar;
  bool _isSaving = false;

  final _genderOptions = const [
    'Chưa rõ',
    'Nam',
    'Nữ',
    'Khác',
  ];

  final _bloodOptions = const [
    'Chưa rõ',
    'O+',
    'A+',
    'B+',
    'AB+',
    'O-',
    'A-',
    'B-',
    'AB-',
  ];

  final _organDonorOptions = const [
    'CHƯA ĐĂNG KÝ',
    'ĐÃ ĐĂNG KÝ',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialFullName);
    _heightCtrl = TextEditingController(text: widget.initialHeight?.replaceAll(' cm', '') ?? '');
    _weightCtrl = TextEditingController(text: widget.initialWeight?.replaceAll(' kg', '') ?? '');
    final rawIce = widget.initialEmergencyContact?.trim() ?? '';
    final initialIceClean = (!rawIce.contains('@')) ? rawIce : '';
    _iceContactCtrl = TextEditingController(text: initialIceClean);
    _allergiesCtrl = TextEditingController(text: widget.initialAllergies ?? '');
    _conditionsCtrl = TextEditingController(text: widget.initialChronicConditions ?? '');
    final rawReg = widget.initialRegion?.trim() ?? '';
    final initialRegionClean = (!rawReg.contains('@') && rawReg != 'Chưa cập nhật') ? rawReg : '';
    _regionCtrl = TextEditingController(text: initialRegionClean);

    final rawGender = widget.initialGender?.trim() ?? 'Chưa rõ';
    _gender = _genderOptions.contains(rawGender) ? rawGender : 'Chưa rõ';

    final rawBlood = widget.initialBloodType?.trim() ?? 'Chưa rõ';
    _bloodType = _bloodOptions.contains(rawBlood) ? rawBlood : 'Chưa rõ';

    if (widget.initialDob != null && widget.initialDob!.isNotEmpty) {
      final parts = widget.initialDob!.split(RegExp(r'[\/\-]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          _selectedDob = DateTime.tryParse('${parts[0]}-${parts[1].padLeft(2, "0")}-${parts[2].padLeft(2, "0")}');
        } else {
          _selectedDob = DateTime.tryParse('${parts[2]}-${parts[1].padLeft(2, "0")}-${parts[0].padLeft(2, "0")}');
        }
      }
    }

    final rawDonor = widget.initialOrganDonor?.trim().toUpperCase() ?? 'CHƯA ĐĂNG KÝ';
    _organDonor = _organDonorOptions.contains(rawDonor) ? rawDonor : 'CHƯA ĐĂNG KÝ';
    _currentAvatar = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _iceContactCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? dobStr;
      if (_selectedDob != null) {
        dobStr = '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}';
      }

      await widget.onSave(
        fullName: _nameCtrl.text.trim(),
        dateOfBirth: dobStr,
        gender: _gender,
        bloodType: _bloodType,
        height: _heightCtrl.text.trim().isNotEmpty ? _heightCtrl.text.trim() : null,
        weight: _weightCtrl.text.trim().isNotEmpty ? _weightCtrl.text.trim() : null,
        emergencyContact: _iceContactCtrl.text.trim().isNotEmpty ? _iceContactCtrl.text.trim() : null,
        allergies: _allergiesCtrl.text.trim().isNotEmpty ? _allergiesCtrl.text.trim() : null,
        chronicConditions: _conditionsCtrl.text.trim().isNotEmpty ? _conditionsCtrl.text.trim() : null,
        organDonor: _organDonor,
        region: (_regionCtrl.text.trim().isNotEmpty && !_regionCtrl.text.trim().contains('@'))
            ? _regionCtrl.text.trim()
            : null,
        avatarUrl: _currentAvatar,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin hồ sơ thành công!'),
            backgroundColor: AppColors.iceOlive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePickAvatar() async {
    await pickAndSaveAvatar(
      context,
      onAvatarSaved: (localPath) async {
        setState(() {
          _currentAvatar = localPath;
        });
        if (widget.onAvatarChanged != null) {
          await widget.onAvatarChanged!(localPath);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, viewInsets.bottom + bottomPadding + 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.iceOlive, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      widget.sheetTitle ?? 'Cập Nhật Thông Tin Cá Nhân',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.iceTextNavy,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Thông tin y tế được mã hóa bảo mật trên máy và đồng bộ vào Thẻ Cấp Cứu ICE.',
              style: AppTypography.caption.copyWith(color: AppColors.iceTextSlate),
            ),
            const Divider(height: 20),

            // Scrollable Form Fields
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // 0. Avatar Preview & Camera Picker
                  Center(
                    child: Stack(
                      children: [
                        ClipOval(
                          child: buildSafeAvatarImage(
                            imageSource: _currentAvatar ?? '',
                            fallbackAsset: 'assets/images/img_profile_avatar.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: AppColors.iceOlive,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _handlePickAvatar,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: _handlePickAvatar,
                      icon: const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.iceOlive),
                      label: const Text('Đổi ảnh đại diện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iceOlive)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. Họ và tên
                  _buildLabel('Họ và tên *'),
                  TextFormField(
                    controller: _nameCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                    decoration: _inputDeco(hint: 'VD: Nguyễn Thu Trang'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),

                  // 1.1 Khu vực sinh sống / Tỉnh thành
                  _buildLabel('Khu vực sinh sống / Tỉnh thành'),
                  TextFormField(
                    controller: _regionCtrl,
                    decoration: _inputDeco(hint: 'VD: TP. Hồ Chí Minh, Hà Nội...'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),

                  // 2. Ngày sinh & Giới tính
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Ngày sinh'),
                            InkWell(
                              onTap: _pickDob,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWarm,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.iceCardBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDob != null
                                          ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                                          : 'Chọn ngày',
                                      style: const TextStyle(fontSize: 13, color: AppColors.iceTextNavy),
                                    ),
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.iceOlive),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Giới tính'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.iceCardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _genderOptions.contains(_gender) ? _gender : 'Chưa rõ',
                                  isExpanded: true,
                                  items: _genderOptions
                                      .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _gender = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Nhóm máu & Hiến tạng
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Nhóm máu'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.iceCardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _bloodOptions.contains(_bloodType) ? _bloodType : 'Chưa rõ',
                                  isExpanded: true,
                                  items: _bloodOptions
                                      .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _bloodType = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Hiến tạng'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.iceCardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _organDonorOptions.contains(_organDonor) ? _organDonor : 'CHƯA ĐĂNG KÝ',
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'CHƯA ĐĂNG KÝ', child: Text('Chưa đăng ký', style: TextStyle(fontSize: 12.5))),
                                    DropdownMenuItem(value: 'ĐÃ ĐĂNG KÝ', child: Text('Đã đăng ký', style: TextStyle(fontSize: 12.5))),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _organDonor = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Chiều cao & Cân nặng
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Chiều cao (cm)'),
                            TextFormField(
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              validator: InputValidators.validateHeightCm,
                              decoration: _inputDeco(hint: 'VD: 165'),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Cân nặng (kg)'),
                            TextFormField(
                              controller: _weightCtrl,
                              keyboardType: TextInputType.number,
                              validator: InputValidators.validateWeightKg,
                              decoration: _inputDeco(hint: 'VD: 58'),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Liên hệ người thân cấp cứu ICE
                  _buildLabel('Người thân liên hệ khẩn cấp (ICE)'),
                  TextFormField(
                    controller: _iceContactCtrl,
                    decoration: _inputDeco(hint: 'VD: Bố - 0988 123 456'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // 6. Cảnh báo dị ứng
                  _buildLabel('Dị ứng thuốc & dị nguyên'),
                  TextFormField(
                    controller: _allergiesCtrl,
                    decoration: _inputDeco(hint: 'VD: Penicillin, Aspirin, hải sản...'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // 7. Bệnh nền mãn tính
                  _buildLabel('Bệnh nền mãn tính'),
                  TextFormField(
                    controller: _conditionsCtrl,
                    decoration: _inputDeco(hint: 'VD: Tăng huyết áp, Viêm dạ dày HP, Hen phế quản...'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Submit Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.iceOlive,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Lưu Thay Đổi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iceTextSlate),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.iceTextMuted),
      filled: true,
      fillColor: AppColors.surfaceWarm,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceOlive)),
    );
  }
}
