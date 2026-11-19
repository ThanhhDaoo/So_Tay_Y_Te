import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../domain/entities/prescription.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
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
  bool _isSaving = false;

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

    if (edit?.prescription?.medicines != null && edit!.prescription!.medicines.isNotEmpty) {
      _medicines.addAll(edit.prescription!.medicines);
    }

    if (edit?.attachments != null && edit!.attachments.isNotEmpty) {
      _attachedFiles.addAll(edit.attachments);
    }
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.iceOlive),
                ),
                title: const Text('Chụp ảnh từ Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chụp sổ khám, kết quả xét nghiệm, đơn thuốc trực tiếp'),
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
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.iceOlive),
                ),
                title: const Text('Chọn ảnh từ Thư viện máy', style: TextStyle(fontWeight: FontWeight.w600)),
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
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'med_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final permanentFile = await File(picked.path).copy('${appDir.path}/$fileName');

      setState(() {
        _attachedFiles.add(permanentFile.path);
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
    }
  }

  void _showAddMedicineDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 viên/lần');
    final freqCtrl = TextEditingController(text: '2 lần/ngày sau ăn');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Thêm Thuốc Vào Toa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
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
            const SizedBox(height: 12),
            TextField(
              controller: dosageCtrl,
              decoration: const InputDecoration(
                labelText: 'Liều lượng',
                hintText: 'VD: 1 viên/lần',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: freqCtrl,
              decoration: const InputDecoration(
                labelText: 'Cách dùng / Thời điểm',
                hintText: 'VD: Uống sau ăn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.iceTextSlate)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iceOlive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _medicines.add(
                    Medicine(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim(),
                      frequency: freqCtrl.text.trim(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final repo = sl.isRegistered<MedicalRecordRepository>()
          ? sl<MedicalRecordRepository>()
          : null;

      final now = DateTime.now();
      final recordId = widget.recordToEdit?.id ??
          'rec_${now.millisecondsSinceEpoch}';

      Prescription? prescription;
      if (_medicines.isNotEmpty || _doctorController.text.trim().isNotEmpty) {
        prescription = Prescription(
          id: widget.recordToEdit?.prescription?.id ?? 'rx_${now.millisecondsSinceEpoch}',
          doctorName: _doctorController.text.trim(),
          hospital: _facilityController.text.trim(),
          issuedDate: _selectedDate,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.recordToEdit != null
              ? 'Đã cập nhật thành công đợt khám!'
              : 'Đã lưu thành công đợt khám mới vào Sổ Tay Y Tế!'),
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
    PrescriptionOcrResultModal.show(
      context,
      onApplyResult: (result) {
        setState(() {
          if (result.hospital != null && result.hospital!.isNotEmpty && _facilityController.text.isEmpty) {
            _facilityController.text = result.hospital!;
          }
          if (result.doctorName != null && result.doctorName!.isNotEmpty && _doctorController.text.isEmpty) {
            _doctorController.text = result.doctorName!;
          }
          if (result.diagnosis != null && result.diagnosis!.isNotEmpty && _diagnosisController.text.isEmpty) {
            _diagnosisController.text = result.diagnosis!;
            if (_titleController.text.isEmpty) {
              _titleController.text = 'Khám ${result.diagnosis!}';
            }
          }
          if (result.imagePath != null && !_attachedFiles.contains(result.imagePath!)) {
            _attachedFiles.add(result.imagePath!);
          }

          final newMeds = result.medicines.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            return Medicine(
              id: 'med_${DateTime.now().millisecondsSinceEpoch}_$idx',
              name: m.name,
              dosage: m.dosage,
              frequency: m.instruction,
            );
          }).toList();

          _medicines.addAll(newMeds);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bóc tách ${result.medicines.length} loại thuốc và tự động điền thông tin đợt khám!'),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 8,
                bottom: 12,
                left: 8,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.iceCardBorder.withValues(alpha: 0.6))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.iceTextNavy),
                    onPressed: () => Navigator.pop(context),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.iceOlive),
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
                    top: 16,
                    bottom: bottomPadding + 32,
                    left: 16,
                    right: 16,
                  ),
                  children: [
                    // 1. General Info Card
                    _buildFormCard(
                      title: 'Thông Tin Cơ Sở Khám',
                      icon: Icons.local_hospital_outlined,
                      children: [
                        _buildInputField(
                          controller: _titleController,
                          label: 'Tên đợt khám / Lý do đến khám *',
                          hint: 'VD: Khám Chuyên Khoa Tiêu Hóa',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập lý do khám' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _facilityController,
                          label: 'Cơ sở khám / Bệnh viện *',
                          hint: 'VD: Bệnh viện Vinmec, Bạch Mai...',
                          validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập cơ sở khám' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ngày khám',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iceTextSlate),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime(1970),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() => _selectedDate = picked);
                                      }
                                    },
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
                                            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.iceTextNavy),
                                          ),
                                          const Icon(Icons.calendar_today, size: 16, color: AppColors.iceOlive),
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
                    const SizedBox(height: 16),

                    // 2. Specialty Selector
                    _buildFormCard(
                      title: 'Chuyên Khoa',
                      icon: Icons.category_outlined,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _specialties.map((spec) {
                            final isSelected = _selectedSpecialty == spec;
                            return ChoiceChip(
                              label: Text(spec),
                              selected: isSelected,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.iceTextNavy,
                              ),
                              selectedColor: AppColors.iceOlive,
                              backgroundColor: AppColors.surfaceWarm,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppColors.iceOlive : AppColors.iceCardBorder,
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedSpecialty = spec);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Clinical Diagnosis
                    _buildFormCard(
                      title: 'Chẩn Đoán Lâm Sàng & Triệu Chứng',
                      icon: Icons.assignment_outlined,
                      children: [
                        _buildInputField(
                          controller: _diagnosisController,
                          label: 'Chẩn đoán xác định của bác sĩ *',
                          hint: 'VD: Viêm dạ dày mạn tính...',
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập chẩn đoán' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _symptomsController,
                          label: 'Triệu chứng & Ghi chú diễn tiến',
                          hint: 'Mô tả triệu chứng người bệnh gặp phải...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Vitals Row
                    _buildFormCard(
                      title: 'Chỉ Số Sinh Hiệu Đo Được',
                      icon: Icons.speed_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _bpController,
                                label: 'Huyết áp (mmHg)',
                                hint: '120/80',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputField(
                                controller: _hrController,
                                label: 'Nhịp tim (bpm)',
                                hint: '72',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. Prescribed Medicines
                    _buildFormCard(
                      title: 'Toa Thuốc Chỉ Định',
                      icon: Icons.medication_outlined,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: _scanPrescriptionOcr,
                            icon: const Icon(Icons.document_scanner_outlined, size: 16, color: AppColors.iceOlive),
                            label: const Text('Quét AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.iceOlive)),
                          ),
                          TextButton.icon(
                            onPressed: _showAddMedicineDialog,
                            icon: const Icon(Icons.add, size: 16, color: AppColors.iceOlive),
                            label: const Text('Thêm tay', style: TextStyle(fontSize: 12, color: AppColors.iceOlive)),
                          ),
                        ],
                      ),
                      children: [
                        if (_medicines.isEmpty)
                          const Text('Chưa có thuốc trong toa.', style: TextStyle(color: AppColors.iceTextMuted, fontSize: 13))
                        else
                          ..._medicines.map((med) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWarm,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.iceCardBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 8, color: AppColors.iceOlive),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(med.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy)),
                                          Text('${med.dosage} • ${med.frequency}', style: const TextStyle(fontSize: 11, color: AppColors.iceTextSlate)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: AppColors.iceTextMuted),
                                      onPressed: () => setState(() => _medicines.remove(med)),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 6. Attachments (Real Photos)
                    _buildFormCard(
                      title: 'Tài Liệu Đính Kèm (Kết quả, Toa, X-quang)',
                      icon: Icons.attach_file_outlined,
                      trailing: TextButton.icon(
                        onPressed: _pickAttachment,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: AppColors.iceOlive),
                        label: const Text('+ Đính kèm ảnh', style: TextStyle(fontSize: 12, color: AppColors.iceOlive, fontWeight: FontWeight.w700)),
                      ),
                      children: [
                        if (_attachedFiles.isEmpty)
                          const Text(
                            'Chưa có ảnh tài liệu đính kèm. Bấm "+ Đính kèm ảnh" để chụp hoặc chọn từ máy.',
                            style: TextStyle(color: AppColors.iceTextMuted, fontSize: 13),
                          )
                        else
                          ..._attachedFiles.map((f) {
                            final name = f.split('/').last;
                            final fileExists = File(f).existsSync();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.iceCardBorder),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      color: Colors.grey.shade200,
                                      child: fileExists
                                          ? Image.file(File(f), fit: BoxFit.cover)
                                          : (f.startsWith('assets/')
                                              ? Image.asset(f, fit: BoxFit.cover)
                                              : const Icon(Icons.image_outlined, color: AppColors.iceOlive)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    onPressed: () => setState(() => _attachedFiles.remove(f)),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit CTA
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRecord,
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        isEdit ? 'Lưu Thay Đổi Đợt Khám' : 'Lưu Đợt Khám Vào Sổ Y Tế',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.iceOlive,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.iceOlive),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iceTextSlate),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: AppColors.iceTextNavy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.iceTextMuted),
            filled: true,
            fillColor: AppColors.surfaceWarm,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              borderSide: const BorderSide(color: AppColors.iceOlive, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
