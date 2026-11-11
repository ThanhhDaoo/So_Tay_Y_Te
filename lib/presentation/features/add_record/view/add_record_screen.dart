import 'package:flutter/material.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../common_widgets/custom_button.dart';
import '../../../common_widgets/custom_text_field.dart';
import 'widgets/medicine_input_list.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<Medicine> _medicines = [];
  MedicalEventType _selectedType = MedicalEventType.generalCheckup;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addSampleMedicine() {
    setState(() {
      _medicines.add(
        Medicine(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Paracetamol 500mg',
          dosage: '1 viên',
          frequency: '2 lần/ngày sau ăn',
        ),
      );
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin đợt khám!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm đợt khám / toa thuốc'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              label: 'Tiêu đề đợt khám',
              hint: 'Ví dụ: Khám họng tại BV Tai Mũi Họng',
              controller: _titleController,
              validator: InputValidators.validateRequired,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MedicalEventType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Phân loại',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: MedicalEventType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Ghi chú / Triệu chứng',
              hint: 'Mô tả triệu chứng hoặc chẩn đoán của bác sĩ',
              controller: _descController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            MedicineInputList(
              medicines: _medicines,
              onAddMedicine: _addSampleMedicine,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Lưu vào sổ y tế',
              icon: Icons.save,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
