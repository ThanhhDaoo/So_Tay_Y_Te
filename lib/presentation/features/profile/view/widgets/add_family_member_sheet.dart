import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/input_validators.dart';

class AddFamilyMemberSheet extends StatefulWidget {
  final void Function(String name, String relation, String bloodType, [String? dob]) onAdd;

  const AddFamilyMemberSheet({super.key, required this.onAdd});

  static void show(
    BuildContext context, {
    required void Function(String name, String relation, String bloodType, [String? dob]) onAdd,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFamilyMemberSheet(onAdd: onAdd),
    );
  }

  @override
  State<AddFamilyMemberSheet> createState() => _AddFamilyMemberSheetState();
}

class _AddFamilyMemberSheetState extends State<AddFamilyMemberSheet> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _selectedRelation = 'Con cái';
  String _selectedBlood = 'O+';

  final _relations = ['Bản thân', 'Vợ / Chồng', 'Con cái', 'Bố mẹ', 'Ông bà'];
  final _bloodTypes = ['Chưa rõ', 'O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nameErr = InputValidators.validateFullName(_nameCtrl.text);
    if (nameErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameErr), backgroundColor: AppColors.error),
      );
      return;
    }

    String? resolvedDob;
    final ageRaw = _ageCtrl.text.trim();
    if (ageRaw.isNotEmpty) {
      final age = int.tryParse(ageRaw);
      if (age == null || age < 0 || age > 130) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tuổi thành viên hợp lệ từ 0 đến 130 tuổi'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final birthYear = DateTime.now().year - age;
      resolvedDob = '01/01/$birthYear ($age tuổi)';
    }

    final name = _nameCtrl.text.trim();
    widget.onAdd(name, _selectedRelation, _selectedBlood, resolvedDob);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm thành viên "$name" vào hồ sơ gia đình!'),
        backgroundColor: AppColors.iceOlive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.group_add_outlined, color: AppColors.iceOlive, size: 24),
                SizedBox(width: 8),
                Text(
                  'Thêm Thành Viên Gia Đình',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Họ và tên thành viên',
                hintText: 'VD: Nguyễn Minh Khang',
                filled: true,
                fillColor: AppColors.surfaceWarm,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Tuổi',
                      hintText: 'VD: 8',
                      filled: true,
                      fillColor: AppColors.surfaceWarm,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBlood,
                    decoration: InputDecoration(
                      labelText: 'Nhóm máu',
                      filled: true,
                      fillColor: AppColors.surfaceWarm,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.iceCardBorder)),
                    ),
                    items: _bloodTypes.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedBlood = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Mối quan hệ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.iceTextSlate)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _relations.map((r) {
                final isSelected = r == _selectedRelation;
                return ChoiceChip(
                  label: Text(r),
                  selected: isSelected,
                  selectedColor: AppColors.iceOlive,
                  backgroundColor: AppColors.surfaceWarm,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.iceTextNavy,
                  ),
                  onSelected: (_) => setState(() => _selectedRelation = r),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Thêm Thành Viên Vào Sổ Gia Đình'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.iceOlive,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
