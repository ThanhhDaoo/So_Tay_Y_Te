import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/data/datasources/local/medical_local_datasource.dart';
import 'package:so_tay_y_te/data/models/medical_event_model.dart';
import 'package:so_tay_y_te/data/repositories/medical_record_repository_impl.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/medicine.dart';
import 'package:so_tay_y_te/domain/entities/prescription.dart';
import 'package:so_tay_y_te/presentation/features/timeline/viewmodel/timeline_viewmodel.dart';

class MockMedicalLocalDataSource implements MedicalLocalDataSource {
  final Map<String, MedicalEventModel> storage = {};

  @override
  Future<List<MedicalEventModel>> getAllEvents({String? userId}) async {
    final list = storage.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<MedicalEventModel?> getEventById(String id) async {
    return storage[id];
  }

  @override
  Future<void> insertOrUpdateEvent(MedicalEventModel event) async {
    storage[event.id] = event;
  }

  @override
  Future<void> deleteEvent(String id) async {
    storage.remove(id);
  }
}

void main() {
  late MockMedicalLocalDataSource localDataSource;
  late MedicalRecordRepositoryImpl repository;

  setUp(() {
    localDataSource = MockMedicalLocalDataSource();
    repository = MedicalRecordRepositoryImpl(localDataSource: localDataSource);
  });

  group('Medical Record CRUD Suite (Thêm, Xem, Sửa, Xóa Bệnh Án)', () {
    test('1. [CREATE] Thêm đợt khám mới lưu đầy đủ thông tin, toa thuốc và đính kèm vào CSDL', () async {
      final newEvent = MedicalEvent(
        id: 'rec_test_001',
        userId: 'user_my_linh',
        title: 'Khám Nội Soi Dạ Dày',
        facilityName: 'Bệnh viện Bạch Mai',
        doctorName: 'Trần Văn Hùng',
        department: 'Tiêu hóa',
        date: DateTime(2026, 11, 19),
        type: MedicalEventType.generalCheckup,
        diagnosis: 'Viêm xung huyết hang vị dạ dày',
        description: 'Đau tức thượng vị, đầy bụng sau ăn',
        bloodPressure: '125/82',
        heartRate: '76',
        prescription: Prescription(
          id: 'rx_001',
          doctorName: 'BS. Trần Văn Hùng',
          hospital: 'Bệnh viện Bạch Mai',
          issuedDate: DateTime(2026, 11, 19),
          medicines: const [
            Medicine(id: 'm1', name: 'Nexium 40mg', dosage: '1v/ngày', frequency: 'Trước ăn sáng'),
            Medicine(id: 'm2', name: 'Gaviscon', dosage: '1 gói/lần', frequency: 'Sau ăn tối'),
          ],
        ),
        attachments: const [
          '/data/user/0/com.sotayyte/app_flutter/phieu_noi_soi.jpg',
        ],
      );

      await repository.saveMedicalEvent(newEvent);

      // Verify Read
      final list = await repository.getMedicalTimeline();
      expect(list.length, equals(1));
      expect(list.first.id, equals('rec_test_001'));
      expect(list.first.title, equals('Khám Nội Soi Dạ Dày'));
      expect(list.first.facilityName, equals('Bệnh viện Bạch Mai'));
      expect(list.first.prescription?.medicines.length, equals(2));
      expect(list.first.attachments.first, contains('phieu_noi_soi.jpg'));
    });

    test('2. [UPDATE] Chỉnh sửa cập nhật đợt khám (đổi chẩn đoán, thêm thuốc mới)', () async {
      final initialEvent = MedicalEvent(
        id: 'rec_test_002',
        title: 'Khám Răng Hàm Mặt',
        facilityName: 'Bệnh viện Răng Hàm Mặt TW',
        date: DateTime(2026, 11, 10),
        type: MedicalEventType.generalCheckup,
        diagnosis: 'Sâu răng số 48',
      );
      await repository.saveMedicalEvent(initialEvent);

      // Cập nhật (Sửa)
      final updatedEvent = MedicalEvent(
        id: 'rec_test_002',
        title: 'Khám Răng Hàm Mặt (Đã Nhổ Răng)',
        facilityName: 'Bệnh viện Răng Hàm Mặt TW',
        doctorName: 'BS. Nguyễn Văn An',
        date: DateTime(2026, 11, 10),
        type: MedicalEventType.surgery,
        diagnosis: 'Đã tiểu phẫu nhổ răng khôn số 48 an toàn',
        prescription: Prescription(
          id: 'rx_dent_002',
          doctorName: 'BS. Nguyễn Văn An',
          issuedDate: DateTime(2026, 11, 10),
          medicines: const [
            Medicine(id: 'm_pain', name: 'Efferalgan Codeine', dosage: '1v/lần', frequency: 'Khi đau'),
          ],
        ),
      );

      await repository.saveMedicalEvent(updatedEvent);

      final retrieved = await repository.getMedicalEventById('rec_test_002');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Khám Răng Hàm Mặt (Đã Nhổ Răng)'));
      expect(retrieved.diagnosis, equals('Đã tiểu phẫu nhổ răng khôn số 48 an toàn'));
      expect(retrieved.prescription?.medicines.first.name, equals('Efferalgan Codeine'));
    });

    test('3. [DELETE] Xóa đợt khám bệnh khỏi sổ y tế thành công', () async {
      final event = MedicalEvent(
        id: 'rec_to_delete',
        title: 'Khám Tạm',
        date: DateTime.now(),
        type: MedicalEventType.generalCheckup,
      );
      await repository.saveMedicalEvent(event);

      var list = await repository.getMedicalTimeline();
      expect(list.any((e) => e.id == 'rec_to_delete'), isTrue);

      await repository.deleteMedicalEvent('rec_to_delete');

      list = await repository.getMedicalTimeline();
      expect(list.any((e) => e.id == 'rec_to_delete'), isFalse);
    });

    test('4. [TIMELINE VIEWMODEL] Load dữ liệu thật và xóa đợt khám trên ViewModel', () async {
      final event1 = MedicalEvent(
        id: 'ev_vm_1',
        title: 'Khám Tim Mạch',
        facilityName: 'Viện Tim TP.HCM',
        date: DateTime(2026, 5, 1),
        type: MedicalEventType.generalCheckup,
        diagnosis: 'Tăng huyết áp vô căn độ 1',
      );
      await repository.saveMedicalEvent(event1);

      final vm = TimelineViewModel(repository: repository);
      await vm.loadRecords();

      expect(vm.state.records.length, equals(1));
      expect(vm.state.records.first.title, equals('Khám Tim Mạch'));
      expect(vm.state.records.first.facilityName, equals('Viện Tim TP.HCM'));

      // Delete via ViewModel
      await vm.deleteRecord('ev_vm_1');
      expect(vm.state.records.any((r) => r.id == 'ev_vm_1'), isFalse);
    });
  });
}
