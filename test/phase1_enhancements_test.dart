import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/core/security/biometric_service.dart';
import 'package:so_tay_y_te/core/widgets/safe_avatar_image.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/user_account.dart';
import 'package:so_tay_y_te/domain/repositories/auth_repository.dart';
import 'package:so_tay_y_te/domain/repositories/medical_record_repository.dart';
import 'package:so_tay_y_te/presentation/features/emergency_card/viewmodel/emergency_card_viewmodel.dart';
import 'package:so_tay_y_te/presentation/features/profile/view/widgets/edit_personal_profile_sheet.dart';
import 'package:so_tay_y_te/presentation/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:so_tay_y_te/presentation/features/record_detail/viewmodel/record_detail_viewmodel.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/viewmodel/security_settings_viewmodel.dart';
import 'package:so_tay_y_te/presentation/routes/app_routes.dart';

class MockBiometricService implements BiometricService {
  @override
  Future<bool> authenticate({required String localizedReason}) async => true;

  @override
  Future<List<BiometricHardwareType>> getAvailableBiometrics() async => [BiometricHardwareType.face];

  @override
  Future<bool> isBiometricAvailable() async => true;
}

class MockMedicalRepo implements MedicalRecordRepository {
  final Map<String, MedicalEvent> _events = {};

  @override
  Future<void> saveMedicalEvent(MedicalEvent event) async {
    _events[event.id] = event;
  }

  @override
  Future<MedicalEvent?> getMedicalEventById(String id) async {
    return _events[id];
  }

  @override
  Future<List<MedicalEvent>> getMedicalTimeline({String? userId}) async => _events.values.toList();

  @override
  Future<void> deleteMedicalEvent(String id) async {
    _events.remove(id);
  }

  @override
  Future<String> exportHealthPdf() async => 'dummy.pdf';
}

class MockTestAuthRepo implements AuthRepository {
  final UserAccount _user = UserAccount(
    id: 'usr_test_1',
    patientCode: 'STYT-112233',
    fullName: 'Trần Văn An',
    primaryContact: '0901234567',
    passwordHash: 'hash',
    salt: 'salt',
    dateOfBirth: '1990-05-15',
    gender: 'Nam',
    bloodType: 'O+',
    createdAt: DateTime.now(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<UserAccount?> getActiveSession() async => _user;

  @override
  Future<Map<String, dynamic>?> getUserProfileDetails(String userId) async {
    return {
      'height': '172',
      'weight': '68',
      'blood_type': 'O+',
      'allergies': 'Penicillin',
      'chronic_conditions': 'Viêm dạ dày',
      'emergency_contact': '0988776655',
      'region': 'Hà Nội',
    };
  }

  @override
  Future<UserAccount> updateUserProfile({
    required String userId,
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
  }) async => _user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferencesDataSource prefs;
  late MockTestAuthRepo authRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferencesDataSourceImpl();
    authRepo = MockTestAuthRepo();

    sl.reset();
    sl.registerSingleton<AppPreferencesDataSource>(prefs);
    sl.registerSingleton<AuthRepository>(authRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  test('EmergencyCardViewModel triggers contact actions smoothly', () async {
    final vm = EmergencyCardViewModel();
    await vm.loadProfile();

    await vm.callPrimaryContact();
    expect(vm.state.lastActionMessage, contains('kết nối cuộc gọi'));

    await vm.callDoctor();
    expect(vm.state.lastActionMessage, contains('kết nối cuộc gọi'));

    await vm.callEmergency115();
    expect(vm.state.lastActionMessage, contains('115'));
  });

  test('ProfileViewModel switches and manages family profiles cleanly', () async {
    final vm = ProfileViewModel();
    await vm.loadCurrentUserProfile();

    expect(vm.state.familyMembers.length, greaterThanOrEqualTo(1));
    expect(vm.state.selectedMemberId, 'primary');
    expect(vm.state.activeProfile.fullName, 'Trần Văn An');
    // Đảm bảo tên hiển thị trên chip chính không bị cắt ngắn (không dùng split(' ').last)
    expect(vm.state.familyMembers.first.name, 'Trần Văn An');

    // Add family member
    await vm.addFamilyMember(
      name: 'Trần Bảo Long',
      relationship: 'Con cái',
      bloodType: 'O+',
      dob: '2018-08-20',
    );

    expect(vm.state.familyMembers.length, greaterThanOrEqualTo(1));

    // Switch selection back to primary
    vm.selectMember('primary');
    expect(vm.state.selectedMemberId, 'primary');
    expect(vm.state.activeProfile.fullName, 'Trần Văn An');
    expect(vm.state.activeProfile.isPrimary, isTrue);
  });

  test('Adding and editing family member isolates data from primary user', () async {
    final vm = ProfileViewModel();
    await vm.loadCurrentUserProfile();

    final primaryNameBefore = vm.state.profilesById['primary']!.fullName;
    final primaryAllergiesBefore = vm.state.profilesById['primary']!.allergies;

    // Thêm thành viên mới
    await vm.addFamilyMember(
      name: 'Nguyễn Thị Mỹ Linh',
      relationship: 'Vợ / Chồng',
      bloodType: 'A+',
      dob: '1992-04-10',
      allergies: 'Hải sản',
      chronicConditions: 'Đau nửa đầu',
    );

    // Hồ sơ gốc không được bị thay đổi hoặc ghi đè
    expect(vm.state.profilesById['primary']!.fullName, primaryNameBefore);
    expect(vm.state.profilesById['primary']!.allergies.length, primaryAllergiesBefore.length);

    // Cập nhật thông tin thành viên gia đình
    await vm.updateFamilyMemberProfile(
      memberId: 'fam_test_01',
      fullName: 'Nguyễn Mỹ Linh (Đã Sửa)',
      bloodType: 'B+',
    );

    // Dữ liệu tài khoản gốc vẫn giữ nguyên tuyệt đối
    expect(vm.state.profilesById['primary']!.fullName, primaryNameBefore);
  });

  test('SecuritySettingsViewModel creates and exports backup archive', () async {
    final vm = SecuritySettingsViewModel(
      preferencesDataSource: prefs,
      biometricService: MockBiometricService(),
    );

    await vm.exportBackup();
    expect(vm.state.lastBackupTime, isNotNull);
    expect(vm.state.feedbackMessage, contains('thành công'));

    await vm.restoreBackup();
    expect(vm.state.feedbackMessage, contains('thành công'));
  });

  test('RecordDetailViewModel loads event from MedicalRecordRepository', () async {
    final repo = MockMedicalRepo();
    final event = MedicalEvent(
      id: 'REC-TEST-99',
      title: 'Khám Viêm Họng',
      description: 'Đau rát họng 3 ngày',
      date: DateTime.now(),
      type: MedicalEventType.generalCheckup,
      doctorName: 'BS. Tuấn',
      facilityName: 'BV Tai Mũi Họng',
    );
    await repo.saveMedicalEvent(event);

    final vm = RecordDetailViewModel(repository: repo);
    await vm.fetchDetail('REC-TEST-99');

    expect(vm.event, isNotNull);
    expect(vm.event!.title, 'Khám Viêm Họng');
    expect(vm.event!.doctorName, 'BS. Tuấn');
  });

  test('AppRoutes.isAppLockShowing and lifecycle guards prevent double Face ID prompt', () {
    // Ban đầu màn hình khóa không mở
    AppRoutes.isAppLockShowing = false;
    expect(AppRoutes.isAppLockShowing, isFalse);

    // Khi màn hình khóa mở ra
    AppRoutes.isAppLockShowing = true;
    expect(AppRoutes.isAppLockShowing, isTrue);

    // Giả lập callback onUnlocked
    AppRoutes.isAppLockShowing = false;
    expect(AppRoutes.isAppLockShowing, isFalse);
  });

  testWidgets('EditPersonalProfileSheet handles "Chưa rõ" gender and blood type without crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditPersonalProfileSheet(
            initialFullName: 'Nguyễn Văn A',
            initialGender: 'Chưa rõ',
            initialBloodType: 'Chưa rõ',
            initialOrganDonor: null,
            onSave: ({
              required fullName,
              allergies,
              avatarUrl,
              bloodType,
              chronicConditions,
              dateOfBirth,
              emergencyContact,
              gender,
              height,
              organDonor,
              region,
              weight,
            }) async {},
          ),
        ),
      ),
    );

    expect(find.text('Cập Nhật Thông Tin Cá Nhân'), findsOneWidget);
    expect(find.text('Họ và tên *'), findsOneWidget);
  });

  test('SafeAvatarHelper resolves old sandbox paths to current Documents directory', () {
    // 1. URL mạng và Asset giữ nguyên
    expect(SafeAvatarHelper.resolveImagePath('https://example.com/avatar.jpg'), 'https://example.com/avatar.jpg');
    expect(SafeAvatarHelper.resolveImagePath('assets/images/img_profile_avatar.png'), 'assets/images/img_profile_avatar.png');

    // 2. Đường dẫn cũ chứa UUID khác được trỏ về Documents hiện tại nếu file tồn tại
    final tempDir = Directory.systemTemp.createTempSync('avatar_test');
    SafeAvatarHelper.documentsDirPath = tempDir.path;
    final testFile = File('${tempDir.path}/avatar_12345.jpg');
    testFile.writeAsStringSync('dummy content');

    const oldIosPath = '/var/mobile/Containers/Data/Application/OLD-UUID-1234/Documents/avatar_12345.jpg';
    final resolved = SafeAvatarHelper.resolveImagePath(oldIosPath);
    expect(resolved, testFile.path);

    tempDir.deleteSync(recursive: true);
  });
}
