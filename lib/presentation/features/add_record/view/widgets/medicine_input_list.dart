import 'package:flutter/material.dart';
import '../../../../../domain/entities/medicine.dart';

class MedicineInputList extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddMedicine;

  const MedicineInputList({
    super.key,
    required this.medicines,
    required this.onAddMedicine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Danh sách thuốc kê đơn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onAddMedicine,
              icon: const Icon(Icons.add),
              label: const Text('Thêm thuốc'),
            ),
          ],
        ),
        if (medicines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Chưa có loại thuốc nào được thêm.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...medicines.map(
            (med) => Card(
              child: ListTile(
                leading: const Icon(Icons.medication),
                title: Text(med.name),
                subtitle: Text('${med.dosage} - ${med.frequency}'),
              ),
            ),
          ),
      ],
    );
  }
}
