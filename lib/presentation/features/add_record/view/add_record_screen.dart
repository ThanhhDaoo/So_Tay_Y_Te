import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../domain/entities/prescription.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../../routes/app_routes.dart';
import '../../prescriptions/view/widgets/prescription_ocr_result_modal.dart';

class AddRecordScreen extends StatefulWidget {
  final MedicalEvent? recordToEdit;

  const AddRecordScreen({super.key, this.recordToEdit});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _facilityController;
  late final TextEditingController _doctorController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _symptomsController;
  late final TextEditingController _bpController;
  late final TextEditingController _hrController;

  late DateTime _selectedDate;
  late String _selectedSpecialty;
  final List<Medicine> _medicines = [];
  final List<String> _attachedFiles = [];
  final Uuid _uuid = const Uuid();
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  // Trạng thái mở rộng các khối tùy chọn (Progressive Disclosure)
  late bool _isVitalsExpanded;
  late bool _isPrescriptionExpanded;
  late bool _isAttachmentsExpanded;

  final List<String> _specialties = [
    'Tiêu hóa',
    'Khám tổng quát',
    'Tim mạch',
    'Tai mũi họng',
    'Hô hấp',
    'Cơ xương khớp',
    'Nhi khoa',
    'Da liễu',
    'Cấp cứu',
    'Tiêm chủng',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.recordToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _facilityController = TextEditingController(text: edit?.facilityName ?? '');
    _doctorController = TextEditingController(text: edit?.doctorName ?? '');
    _diagnosisController = TextEditingController(text: edit?.diagnosis ?? '');
    _symptomsController = TextEditingController(text: edit?.description ?? '');
    _bpController = TextEditingController(text: edit?.bloodPressure ?? '');
    _hrController = TextEditingController(text: edit?.heartRate ?? '');

    _selectedDate = edit?.date ?? DateTime.now();
    _selectedSpecialty = edit?.department ?? 'Khám tổng quát';
    if (!_specialties.contains(_selectedSpecialty)) {
      _specialties.insert(0, _selectedSpecialty);
    }

    if (edit?.prescription?.medicines != null &&
        edit!.prescription!.medicines.isNotEmpty) {
      _medicines.addAll(edit.prescription!.medicines);
    }

    if (edit?.attachments != null && edit!.attachments.isNotEmpty) {
      _attachedFiles.addAll(edit.attachments);
    }

    _isVitalsExpanded = (_bpController.text.trim().isNotEmpty ||
        _hrController.text.trim().isNotEmpty);
    _isPrescriptionExpanded = _medicines.isNotEmpty;
    _isAttachmentsExpanded = _attachedFiles.isNotEmpty;

    for (final ctrl in [
      _titleController,
      _facilityController,
      _doctorController,
      _diagnosisController,
      _symptomsController,
      _bpController,
      _hrController,
    ]) {
      ctrl.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_hasUnsavedChanges && mounted) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges || _isSaving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hủy Thay Đổi Chưa Lưu?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.iceTextNavy,
          ),
        ),
        content: const Text(
          'Thông tin đợt khám và toa thuốc bạn đang nhập sẽ bị mất nếu thoát ngay bây giờ.',
          style: TextStyle(fontSize: 13.5, color: AppColors.iceTextSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục nhập'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát không lưu'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _facilityController.dispose();
    _doctorController.dispose();
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    setState(() => _isAttachmentsExpanded = true);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: AppLayoutTokens.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Đính Kèm Tài Liệu / Hình Ảnh Bệnh Án',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.iceTextNavy,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWarm,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.iceOlive,
                  ),
                ),
                title: const Text(
                  'Chụp ảnh từ Camera',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Chụp sổ khám, kết quả xét nghiệm, đơn thuốc trực tiếp',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _captureAndSaveImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWarm,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.iceOlive,
                  ),
                ),
                title: const Text(
                  'Chọn ảnh từ Thư viện máy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Chọn ảnh hoặc file phiếu khám có sẵn'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _captureAndSaveImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureAndSaveImage(ImageSource source) async {
    AppRoutes.isExternalPickerActive = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;

      final pickedFile = File(picked.path);
      final fileBytes = await pickedFile.length();
      if (fileBytes > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tệp ảnh vượt quá giới hạn 20MB. Vui lòng chọn ảnh nhẹ hơn.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._\-]'), '_');
      final fileName =
          'med_${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final permanentFile = await pickedFile.copy('${appDir.path}/$fileName');

      setState(() {
        _attachedFiles.add(permanentFile.path);
        _isAttachmentsExpanded = true;
        _hasUnsavedChanges = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đính kèm ảnh tài liệu y tế thành công!'),
            backgroundColor: AppColors.iceOlive,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      AppRoutes.isExternalPickerActive = false;
    }
  }

  void _showAddMedicineDialog({int? editIndex}) {
    setState(() => _isPrescriptionExpanded = true);
    final existing =
        (editIndex != null && editIndex >= 0 && editIndex < _medicines.length)
            ? _medicines[editIndex]
            : null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dosageCtrl =
        TextEditingController(text: existing?.dosage ?? '1 viên/lần');
    final freqCtrl = TextEditingController(
      text: existing?.frequency ?? '2 lần/ngày sau ăn',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing != null ? 'Chỉnh Sửa Thuốc Trong Toa' : 'Thêm Thuốc Vào Toa',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.iceTextNavy,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên biệt dược / hàm lượng',
                hintText: 'VD: Panadol Extra 500mg',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Liều lượng',
                hintText: 'VD: 1 viên/lần',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: freqCtrl,
              decoration: const InputDecoration(
                labelText: 'Cách dùng / Thời điểm (Sáng, Trưa, Tối)',
                hintText: 'VD: Sáng 1 viên, Tối 1 viên sau ăn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.iceTextSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iceOlive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  final med = Medicine(
                    id: existing?.id ?? _uuid.v4(),
                    name: nameCtrl.text.trim(),
                    dosage: dosageCtrl.text.trim().isNotEmpty
                        ? dosageCtrl.text.trim()
                        : 'Theo đơn',
                    frequency: freqCtrl.text.trim().isNotEmpty
                        ? freqCtrl.text.trim()
                        : 'Theo chỉ dẫn bác sĩ',
                    instructions: freqCtrl.text.trim(),
                  );
                  if (existing != null && editIndex != null) {
                    _medicines[editIndex] = med;
                  } else {
                    _medicines.add(med);
                  }
                  _isPrescriptionExpanded = true;
                  _hasUnsavedChanges = true;
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(existing != null ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_isSaving) return;

    // Mở khối Sinh hiệu nếu có lỗi nhập huyết áp / nhịp tim
    if (InputValidators.validateBloodPressure(_bpController.text) != null ||
        InputValidators.validateHeartRate(_hrController.text) != null) {
      setState(() => _isVitalsExpanded = true);
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final repo = sl.isRegistered<MedicalRecordRepository>()
          ? sl<MedicalRecordRepository>()
          : null;

      final now = DateTime.now();
      final recordId = widget.recordToEdit?.id ?? _uuid.v4();

      Prescription? prescription;
      if (_medicines.isNotEmpty) {
        prescription = Prescription(
          id: widget.recordToEdit?.prescription?.id ?? _uuid.v4(),
          doctorName: _doctorController.text.trim(),
          hospital: _facilityController.text.trim(),
          issuedDate: _selectedDate,
          durationDays: widget.recordToEdit?.prescription?.durationDays ?? 14,
          status: widget.recordToEdit?.prescription?.status ?? 'active',
          medicines: _medicines,
          note: _diagnosisController.text.trim(),
        );
      }

      MedicalEventType eventType = MedicalEventType.generalCheckup;
      if (_selectedSpecialty == 'Cấp cứu') {
        eventType = MedicalEventType.emergency;
      } else if (_selectedSpecialty == 'Tiêm chủng') {
        eventType = MedicalEventType.vaccination;
      }

      final event = MedicalEvent(
        id: recordId,
        userId: widget.recordToEdit?.userId,
        memberId: widget.recordToEdit?.memberId ??
            AppSessionNotifier.instance.activeMemberId,
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Đợt khám $_selectedSpecialty',
        description: _symptomsController.text.trim(),
        date: _selectedDate,
        type: eventType,
        facilityName: _facilityController.text.trim(),
        doctorName: _doctorController.text.trim(),
        department: _selectedSpecialty,
        diagnosis: _diagnosisController.text.trim(),
        bloodPressure: _bpController.text.trim(),
        heartRate: _hrController.text.trim(),
        spo2: widget.recordToEdit?.spo2,
        temperature: widget.recordToEdit?.temperature,
        prescription: prescription,
        attachments: _attachedFiles,
        hospitalFee: widget.recordToEdit?.hospitalFee,
        createdAt: widget.recordToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      if (repo != null) {
        await repo.saveMedicalEvent(event);
      }

      if (!mounted) return;
      _hasUnsavedChanges = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.recordToEdit != null
                ? 'Đã cập nhật thành công đợt khám!'
                : 'Đã lưu thành công đợt khám mới vào Sổ Tay Y Tế!',
          ),
          backgroundColor: AppColors.iceOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu đợt khám: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _scanPrescriptionOcr() {
    setState(() => _isPrescriptionExpanded = true);
    PrescriptionOcrResultModal.show(
      context,
      onApplyResult: (result) {
        setState(() {
          if (result.hospital != null &&
              result.hospital!.isNotEmpty &&
              _facilityController.text.isEmpty) {
            _facilityController.text = result.hospital!;
          }
          if (result.doctorName != null &&
              result.doctorName!.isNotEmpty &&
              _doctorController.text.isEmpty) {
            _doctorController.text = result.doctorName!;
          }
          if (result.diagnosis != null &&
              result.diagnosis!.isNotEmpty &&
              _diagnosisController.text.isEmpty) {
            _diagnosisController.text = result.diagnosis!;
            if (_titleController.text.isEmpty) {
              _titleController.text = 'Khám ${result.diagnosis!}';
            }
          }
          if (result.imagePath != null &&
              !_attachedFiles.contains(result.imagePath!)) {
            _attachedFiles.add(result.imagePath!);
            _isAttachmentsExpanded = true;
          }

          final newMeds = result.medicines.map((m) {
            return Medicine(
              id: _uuid.v4(),
              name: m.name,
              dosage: m.dosage,
              frequency: m.instruction,
              instructions: m.instruction,
            );
          }).toList();

          _medicines.addAll(newMeds);
          _isPrescriptionExpanded = true;
          _hasUnsavedChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã bóc tách ${result.medicines.length} loại thuốc. Chạm vào từng thuốc nếu cần sửa lại!',
            ),
            backgroundColor: AppColors.iceOlive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isEdit = widget.recordToEdit != null;

    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscardIfNeeded();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.iceBackground,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 8,
                  bottom: 12,
                  left: 10,
                  right: AppLayoutTokens.screenPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.iceCardBorder.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: AppColors.iceTextNavy,
                      ),
                      onPressed: () async {
                        final shouldPop = await _confirmDiscardIfNeeded();
                        if (shouldPop && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isEdit ? 'Chỉnh Sửa Đợt Khám' : 'Thêm Đợt Khám Mới',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _saveRecord,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.iceOlive,
                              ),
                            )
                          : Text(
                              isEdit ? 'Cập nhật' : 'Lưu',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.iceOlive,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Form Body
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 20,
                      bottom: bottomPadding + 36,
                      left: AppLayoutTokens.screenPadding,
                      right: AppLayoutTokens.screenPadding,
                    ),
                    children: [
                      // Cụm 1: Thông tin cốt lõi bắt buộc (Cơ sở khám + Chuyên khoa cuộn ngang gọn)
                      SectionContainer(
                        title: 'Thông Tin Cơ Sở Khám',
                        icon: Icons.local_hospital_outlined,
                        bottomSpacing: AppLayoutTokens.sectionGap,
                        child: CleanCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                controller: _titleController,
                                label: 'Tên đợt khám / Lý do đến khám *',
                                hint: 'VD: Khám Chuyên Khoa Tiêu Hóa',
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Vui lòng nhập lý do khám'
                                        : null,
                              ),
                              const SizedBox(
                                height: AppLayoutTokens.formFieldGap,
                              ),
                              _buildInputField(
                                controller: _facilityController,
                                label: 'Cơ sở khám / Bệnh viện *',
                                hint: 'VD: Bệnh viện Vinmec, Bạch Mai...',
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Vui lòng nhập cơ sở khám'
                                        : null,
                              ),
                              const SizedBox(
                                height: AppLayoutTokens.formFieldGap,
                              ),
                              const Text(
                                'Chuyên Khoa',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.iceTextSlate,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 38,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _specialties.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final spec = _specialties[index];
                                    final isSelected =
                                        _selectedSpecialty == spec;
                                    return ChoiceChip(
                                      label: Text(spec),
                                      selected: isSelected,
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.iceTextNavy,
                                      ),
                                      selectedColor: AppColors.iceOlive,
                                      backgroundColor: AppColors.surfaceWarm,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppColors.iceOlive
                                              : AppColors.iceCardBorder,
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedSpecialty = spec;
                                            _hasUnsavedChanges = true;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: AppLayoutTokens.formFieldGap,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      controller: _doctorController,
                                      label: 'Bác sĩ điều trị',
                                      hint: 'VD: BS. Trần Văn Hùng',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ngày khám',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.iceTextSlate,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () async {
                                            final today = DateTime.now();
                                            final safeInitial =
                                                _selectedDate.isAfter(today)
                                                    ? today
                                                    : _selectedDate;
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: safeInitial,
                                              firstDate: DateTime(1920),
                                              lastDate: today,
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                _selectedDate = picked;
                                                _hasUnsavedChanges = true;
                                              });
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 13,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceWarm,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.iceCardBorder,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    color:
                                                        AppColors.iceTextNavy,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: AppColors.iceOlive,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Cụm 2: Chẩn đoán lâm sàng (luôn mở)
                      SectionContainer(
                        title: 'Chẩn Đoán & Triệu Chứng',
                        icon: Icons.assignment_outlined,
                        bottomSpacing: AppLayoutTokens.sectionGap,
                        child: CleanCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                controller: _diagnosisController,
                                label: 'Chẩn đoán xác định của bác sĩ *',
                                hint: 'VD: Viêm dạ dày mạn tính...',
                                maxLines: 2,
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Vui lòng nhập chẩn đoán'
                                        : null,
                              ),
                              const SizedBox(
                                height: AppLayoutTokens.formFieldGap,
                              ),
                              _buildInputField(
                                controller: _symptomsController,
                                label: 'Triệu chứng & Ghi chú diễn tiến',
                                hint:
                                    'Mô tả triệu chứng người bệnh gặp phải...',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Cụm 3: Dữ liệu bổ sung (Progressive Disclosure: Đóng/Mở thông minh)
                      SectionContainer(
                        title: 'Thông Tin Bổ Sung (Tùy Chọn)',
                        subtitle: 'Chạm từng mục bên dưới để thêm sinh hiệu, toa thuốc hoặc ảnh chụp',
                        icon: Icons.playlist_add_circle_outlined,
                        bottomSpacing: 28,
                        child: Column(
                          children: [
                            // 3.1 Sinh hiệu (vẫn giữ state trong cây Form bằng Visibility maintainState)
                            _buildCollapsibleModule(
                              title: 'Chỉ Số Sinh Hiệu Đo Được',
                              subtitle: (_bpController.text.isNotEmpty ||
                                      _hrController.text.isNotEmpty)
                                  ? 'Đã nhập chỉ số đo'
                                  : 'Huyết áp, Nhịp tim',
                              icon: Icons.speed_outlined,
                              isExpanded: _isVitalsExpanded,
                              onToggle: () => setState(
                                () => _isVitalsExpanded = !_isVitalsExpanded,
                              ),
                              child: Visibility(
                                visible: _isVitalsExpanded,
                                maintainState: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildInputField(
                                          controller: _bpController,
                                          label: 'Huyết áp (mmHg)',
                                          hint: 'VD: 120/80',
                                          validator: InputValidators
                                              .validateBloodPressure,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildInputField(
                                          controller: _hrController,
                                          label: 'Nhịp tim (bpm)',
                                          hint: 'VD: 72',
                                          validator:
                                              InputValidators.validateHeartRate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppLayoutTokens.cardGap),

                            // 3.2 Toa thuốc chỉ định
                            _buildCollapsibleModule(
                              title: 'Toa Thuốc Chỉ Định',
                              subtitle: _medicines.isNotEmpty
                                  ? 'Đã thêm ${_medicines.length} loại thuốc'
                                  : 'Quét đơn AI hoặc nhập tay',
                              icon: Icons.medication_outlined,
                              isExpanded: _isPrescriptionExpanded,
                              onToggle: () => setState(
                                () => _isPrescriptionExpanded =
                                    !_isPrescriptionExpanded,
                              ),
                              child: _isPrescriptionExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        AppColors.iceOlive,
                                                    side: const BorderSide(
                                                      color: AppColors
                                                          .iceCardBorder,
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 10,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      _scanPrescriptionOcr,
                                                  icon: const Icon(
                                                    Icons
                                                        .document_scanner_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Quét đơn AI',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        AppColors.iceOlive,
                                                    side: const BorderSide(
                                                      color: AppColors
                                                          .iceCardBorder,
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 10,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _showAddMedicineDialog(),
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Thêm thuốc tay',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_medicines.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            ..._medicines
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final idx = entry.key;
                                              final med = entry.value;
                                              return InkWell(
                                                onTap: () =>
                                                    _showAddMedicineDialog(
                                                  editIndex: idx,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.surfaceWarm,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              med.name,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: AppColors
                                                                    .iceTextNavy,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              '${med.dosage} • ${med.frequency}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .iceTextSlate,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Sửa thuốc',
                                                        icon: const Icon(
                                                          Icons.edit_outlined,
                                                          size: 16,
                                                          color: AppColors
                                                              .iceOlive,
                                                        ),
                                                        onPressed: () =>
                                                            _showAddMedicineDialog(
                                                          editIndex: idx,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Xóa thuốc',
                                                        icon: const Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color: AppColors
                                                              .iceTextMuted,
                                                        ),
                                                        onPressed: () =>
                                                            setState(() {
                                                          _medicines
                                                              .removeAt(idx);
                                                          _hasUnsavedChanges =
                                                              true;
                                                        }),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: AppLayoutTokens.cardGap),

                            // 3.3 Tài liệu đính kèm
                            _buildCollapsibleModule(
                              title: 'Tài Liệu Đính Kèm',
                              subtitle: _attachedFiles.isNotEmpty
                                  ? 'Đã đính kèm ${_attachedFiles.length} ảnh'
                                  : 'Phiếu xét nghiệm, X-Quang, đơn thuốc',
                              icon: Icons.attach_file_outlined,
                              isExpanded: _isAttachmentsExpanded,
                              onToggle: () => setState(
                                () => _isAttachmentsExpanded =
                                    !_isAttachmentsExpanded,
                              ),
                              child: _isAttachmentsExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.iceOlive,
                                                side: const BorderSide(
                                                  color:
                                                      AppColors.iceCardBorder,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: _pickAttachment,
                                              icon: const Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                '+ Đính kèm ảnh từ máy / Camera',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_attachedFiles.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            ..._attachedFiles.map((f) {
                                              final name = f.split('/').last;
                                              final fileExists =
                                                  File(f).existsSync();
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceWarm,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6,
                                                      ),
                                                      child: Container(
                                                        width: 44,
                                                        height: 44,
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: fileExists
                                                            ? Image.file(
                                                                File(f),
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                            : (f.startsWith(
                                                                'assets/',
                                                              )
                                                                ? Image.asset(
                                                                    f,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                                : const Icon(
                                                                    Icons
                                                                        .image_outlined,
                                                                    color: AppColors
                                                                        .iceOlive,
                                                                  )),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .iceTextNavy,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        size: 18,
                                                        color: Colors.redAccent,
                                                      ),
                                                      onPressed: () =>
                                                          setState(() {
                                                        _attachedFiles
                                                            .remove(f);
                                                        _hasUnsavedChanges =
                                                            true;
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      // Submit CTA
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveRecord,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          isEdit
                              ? 'Lưu Thay Đổi Đợt Khám'
                              : 'Lưu Đợt Khám Vào Sổ Y Tế',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.iceOlive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleModule({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return CleanCard(
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: AppColors.iceOlive),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
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
                          color: AppColors.iceTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 20,
                  color: AppColors.iceOlive,
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.iceTextSlate,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, color: AppColors.iceTextNavy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.iceTextMuted,
            ),
            errorMaxLines: 3,
            errorStyle: const TextStyle(fontSize: 11.5, height: 1.25),
            filled: true,
            fillColor: AppColors.surfaceWarm,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.iceCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.iceCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.iceOlive,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
