import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/medicine.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Khám Chuyên Khoa Tiêu Hóa');
  final _facilityController = TextEditingController(text: 'Bệnh viện Đa khoa Quốc tế Vinmec');
  final _doctorController = TextEditingController(text: 'BS. Trần Văn Hùng');
  final _diagnosisController = TextEditingController(text: 'Viêm dạ dày - tá tràng mạn tính HP (+)');
  final _symptomsController = TextEditingController(text: 'Đau âm ỉ thượng vị, ợ hơi nhẹ sau ăn.');
  final _bpController = TextEditingController(text: '120/80');
  final _hrController = TextEditingController(text: '72');

  DateTime _selectedDate = DateTime.now();
  String _selectedSpecialty = 'Tiêu hóa';

  final List<String> _specialties = [
    'Tiêu hóa',
    'Khám tổng quát',
    'Tim mạch',
    'Tai mũi họng',
    'Hô hấp',
    'Cơ xương khớp',
    'Nhi khoa',
  ];

  final List<Medicine> _medicines = [
    Medicine(
      id: '1',
      name: 'Nexium 40mg',
      dosage: '1 viên/lần',
      frequency: 'Trước ăn sáng 30p',
    ),
    Medicine(
      id: '2',
      name: 'Amoxicillin 500mg',
      dosage: '2 viên/lần',
      frequency: '2 lần/ngày sau ăn',
    ),
  ];

  final List<String> _attachedFiles = [
    'Phieu_Noi_Soi_Da_Day.jpg',
    'Ket_Qua_Xet_Nghiem_Mau.pdf',
  ];

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

  void _saveRecord() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thành công đợt khám mới vào Sổ Tay Y Tế!'),
          backgroundColor: AppColors.iceOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'SỔ TAY Y TẾ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.55,
                            color: AppColors.iceOlive,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Thêm Đợt Khám Mới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _saveRecord,
                    child: const Text(
                      'LƯU',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.iceOlive),
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
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottomPadding),
                  children: [
                    // 1. Basic Info Card
                    _buildFormCard(
                      title: 'Thông Tin Cơ Sở Khám',
                      icon: Icons.local_hospital_outlined,
                      children: [
                        _buildInputField(
                          controller: _titleController,
                          label: 'Tiêu đề đợt khám',
                          hint: 'VD: Khám tiêu hóa định kỳ',
                          validator: (v) => v?.trim().isEmpty == true ? 'Vui lòng nhập tiêu đề' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _facilityController,
                          label: 'Bệnh viện / Phòng khám',
                          hint: 'VD: Bệnh viện Vinmec, Bạch Mai...',
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
                                  const Text('Ngày khám', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iceTextSlate)),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) setState(() => _selectedDate = picked);
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
                                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
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
                          children: _specialties.map((s) {
                            final isSelected = s == _selectedSpecialty;
                            return ChoiceChip(
                              label: Text(s),
                              selected: isSelected,
                              selectedColor: AppColors.iceOlive,
                              backgroundColor: AppColors.surfaceWarm,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.iceTextNavy,
                              ),
                              onSelected: (_) => setState(() => _selectedSpecialty = s),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Diagnosis & Symptoms
                    _buildFormCard(
                      title: 'Chẩn Đoán & Triệu Chứng',
                      icon: Icons.note_alt_outlined,
                      children: [
                        _buildInputField(
                          controller: _diagnosisController,
                          label: 'Chẩn đoán của bác sĩ',
                          hint: 'VD: Viêm loét dạ dày, Rối loạn tiêu hóa...',
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _symptomsController,
                          label: 'Triệu chứng & Ghi chú',
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
                      trailing: TextButton.icon(
                        onPressed: _showAddMedicineDialog,
                        icon: const Icon(Icons.add, size: 16, color: AppColors.iceOlive),
                        label: const Text('Thêm thuốc', style: TextStyle(fontSize: 12, color: AppColors.iceOlive)),
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

                    // 6. Attachments
                    _buildFormCard(
                      title: 'Tài Liệu Đính Kèm (Kết quả, Toa, X-quang)',
                      icon: Icons.attach_file_outlined,
                      trailing: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _attachedFiles.add('Tep_Dinh_Kem_${DateTime.now().second}.jpg');
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đính kèm ảnh tài liệu y tế'),
                              backgroundColor: AppColors.iceOlive,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: AppColors.iceOlive),
                        label: const Text('Thêm tệp', style: TextStyle(fontSize: 12, color: AppColors.iceOlive)),
                      ),
                      children: [
                        ..._attachedFiles.map((f) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined, size: 18, color: AppColors.iceOlive),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(f, style: const TextStyle(fontSize: 12, color: AppColors.iceTextNavy))),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                    onPressed: () => setState(() => _attachedFiles.remove(f)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit CTA
                    ElevatedButton.icon(
                      onPressed: _saveRecord,
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('Lưu Đợt Khám Vào Sổ Y Tế', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
