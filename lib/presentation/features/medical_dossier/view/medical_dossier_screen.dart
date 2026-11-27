import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/local/elder_care_local_datasource.dart';
import '../../../../data/repositories/elder_care_repository_impl.dart';
import '../../../../domain/repositories/elder_care_repository.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../../../routes/app_routes.dart';
import '../../profile/view/widgets/edit_personal_profile_sheet.dart';
import '../../profile/view/widgets/profile_family_switcher.dart';
import '../../profile/viewmodel/profile_state.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../../timeline/view/widgets/timeline_record_card.dart';
import '../../timeline/viewmodel/timeline_state.dart';
import '../../timeline/viewmodel/timeline_viewmodel.dart';
import 'widgets/special_history_notice_card.dart';

/// Trang Hồ sơ & Bệnh án chuẩn 40+:
/// Sắp xếp đúng thứ tự bắt buộc:
/// (1) Tổng quan sức khỏe
/// (2) Tiền sử bệnh án từ trước đến giờ + Khung Lưu ý đặc biệt về tiền sử bệnh (nổi bật, dễ nhìn)
/// (3) Dòng thời gian bệnh án (Timeline) từ mới đến cũ
class MedicalDossierScreen extends StatefulWidget {
  final bool showBottomNav;

  const MedicalDossierScreen({
    super.key,
    this.showBottomNav = false,
  });

  @override
  State<MedicalDossierScreen> createState() => _MedicalDossierScreenState();
}

class _MedicalDossierScreenState extends State<MedicalDossierScreen> {
  late final ProfileViewModel _profileVm;
  late final TimelineViewModel _timelineVm;
  String _specialHistoryNote = '';
  int _lastGlobalVer = AppSessionNotifier.instance.medicalRecordsVersion;

  @override
  void initState() {
    super.initState();
    _profileVm = ProfileViewModel();
    _timelineVm = TimelineViewModel();
    _loadSpecialNote();
    AppSessionNotifier.instance.addListener(_onSessionUpdated);
  }

  void _onSessionUpdated() {
    final ver = AppSessionNotifier.instance.medicalRecordsVersion;
    if (ver != _lastGlobalVer) {
      _lastGlobalVer = ver;
      _loadSpecialNote();
    }
  }

  ElderCareRepository? _resolveElderRepo() {
    if (sl.isRegistered<ElderCareRepository>()) {
      return sl<ElderCareRepository>();
    }
    if (sl.isRegistered<DatabaseHelper>()) {
      return ElderCareRepositoryImpl(
        localDataSource:
            ElderCareLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
      );
    }
    return null;
  }

  Future<void> _loadSpecialNote() async {
    final repo = _resolveElderRepo();
    if (repo == null) return;
    final note = await repo.getSpecialHistoryNote(
      memberId: AppSessionNotifier.instance.activeMemberId,
    );
    if (mounted) {
      setState(() => _specialHistoryNote = note);
    }
  }

  Future<void> _saveSpecialNote(String note) async {
    final repo = _resolveElderRepo();
    if (repo == null) return;
    await repo.saveSpecialHistoryNote(
      note: note,
      memberId: AppSessionNotifier.instance.activeMemberId,
    );
    if (mounted) {
      setState(() => _specialHistoryNote = note);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã lưu Lưu ý đặc biệt về tiền sử bệnh!',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    AppSessionNotifier.instance.removeListener(_onSessionUpdated);
    _profileVm.dispose();
    _timelineVm.dispose();
    super.dispose();
  }

  void _openEditMedicalHistorySheet(MemberMedicalProfile activeProfile) {
    final isPrimary = activeProfile.id == 'primary';
    EditPersonalProfileSheet.show(
      context,
      sheetTitle: isPrimary
          ? 'Cập Nhật Thể Trạng & Tiền Sử Bệnh'
          : 'Cập Nhật Hồ Sơ: ${activeProfile.fullName}',
      initialFullName: activeProfile.fullName,
      initialDob: activeProfile.dob,
      initialGender: activeProfile.gender,
      initialBloodType: activeProfile.bloodType,
      initialHeight: activeProfile.heightText.replaceAll(' cm', ''),
      initialWeight: activeProfile.weightText.replaceAll(' kg', ''),
      initialEmergencyContact: activeProfile.contact,
      initialRegion: activeProfile.region != 'Chưa cập nhật'
          ? activeProfile.region
          : '',
      initialAvatarUrl: activeProfile.heroImageAsset,
      initialAllergies:
          activeProfile.allergies.map((a) => a.title).join(', '),
      initialChronicConditions:
          activeProfile.chronicConditions.map((c) => c.title).join(', '),
      onSave: ({
        required fullName,
        allergies,
        bloodType,
        chronicConditions,
        dateOfBirth,
        emergencyContact,
        gender,
        height,
        organDonor,
        weight,
        region,
        avatarUrl,
      }) async {
        if (isPrimary) {
          await _profileVm.updateCurrentUserProfile(
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            gender: gender,
            bloodType: bloodType,
            height: height,
            weight: weight,
            emergencyContact: emergencyContact,
            allergies: allergies,
            chronicConditions: chronicConditions,
            organDonor: organDonor,
            region: region,
            avatarUrl: avatarUrl,
          );
        } else {
          await _profileVm.updateFamilyMemberProfile(
            memberId: activeProfile.id,
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            gender: gender,
            bloodType: bloodType,
            height: height,
            weight: weight,
            emergencyContact: emergencyContact,
            allergies: allergies,
            chronicConditions: chronicConditions,
            avatarUrl: avatarUrl,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: Listenable.merge([_profileVm, _timelineVm]),
      builder: (context, _) {
        final pState = _profileVm.state;
        final tState = _timelineVm.state;
        final activeProfile = pState.activeProfile;
        final records = tState.filteredRecords;

        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBodyBehindAppBar: true,
          appBar: MedVaultGlassAppBar(
            title: 'Hồ Sơ & Bệnh Án',
            trailing: SeniorLabeledIconButton(
              icon: Icons.folder_outlined,
              label: 'Tài liệu',
              onTap: () => Navigator.pushNamed(context, AppRoutes.documents),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.iceOlive,
            onRefresh: () async {
              await _profileVm.loadCurrentUserProfile();
              await _timelineVm.loadRecords();
              await _loadSpecialNote();
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppLayoutTokens.screenPadding,
                topPad + 78,
                AppLayoutTokens.screenPadding,
                bottomPad + 140,
              ),
              children: [
                // Chuyển đổi nhanh thành viên gia đình nếu có nhiều hồ sơ
                if (pState.familyMembers.length > 1) ...[
                  ProfileFamilySwitcher(
                    members: pState.familyMembers,
                    selectedMemberId: pState.selectedMemberId,
                    onSelectMember: (id) {
                      _profileVm.selectMember(id);
                      _loadSpecialNote();
                    },
                    onAddMemberTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profile),
                    onVaultProTap: () =>
                        Navigator.pushNamed(context, AppRoutes.paywall),
                  ),
                  const SizedBox(height: 20),
                ],

                // =============================================================
                // PHẦN (1): TỔNG QUAN SỨC KHỎE
                // =============================================================
                SeniorSectionBlock(
                  title: '1. Tổng quan sức khỏe',
                  subtitle: 'Hồ sơ: ${activeProfile.fullName}',
                  icon: Icons.analytics_outlined,
                  iconColor: AppColors.primary,
                  trailing: SeniorLabeledIconButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Xuất PDF',
                    color: AppColors.primary,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.vitalReports),
                  ),
                  child: SeniorCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _VitalMetricBox(
                                label: 'Huyết áp gần nhất',
                                value: tState.latestBloodPressure ?? '--/--',
                                unit: 'mmHg',
                                icon: Icons.monitor_heart_outlined,
                                accent: AppColors.reportTeal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _VitalMetricBox(
                                label: 'Nhịp tim gần nhất',
                                value: tState.latestHeartRate ?? '--',
                                unit: 'nhịp/phút',
                                icon: Icons.favorite_border_rounded,
                                accent: AppColors.textWarmBrown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _VitalMetricBox(
                                label: 'Nhóm máu',
                                value: activeProfile.bloodType,
                                unit: 'Hệ ABO/Rh',
                                icon: Icons.water_drop_outlined,
                                accent: AppColors.iceCriticalBadge,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _VitalMetricBox(
                                label: 'Chỉ số BMI',
                                value: activeProfile.bmiValue,
                                unit: activeProfile.bmiStatusLabel,
                                icon: Icons.accessibility_new_rounded,
                                accent: AppColors.iceOlive,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCream,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Chiều cao: ${activeProfile.heightText}  •  Cân nặng: ${activeProfile.weightText}  •  Tổng số bệnh án đã lưu: ${tState.records.length} hồ sơ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iceTextNavy,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =============================================================
                // PHẦN (2): TIỀN SỬ BỆNH ÁN & KHUNG LƯU Ý ĐẶC BIỆT
                // =============================================================
                SeniorSectionBlock(
                  title: '2. Tiền sử bệnh án & Lưu ý đặc biệt',
                  subtitle: 'Thông tin quan trọng cần trình bác sĩ khi đi khám',
                  icon: Icons.assignment_late_rounded,
                  iconColor: SeniorTokens.warningAmberText,
                  iconBgColor: SeniorTokens.warningAmberBg,
                  trailing: SeniorLabeledIconButton(
                    icon: Icons.edit_rounded,
                    label: 'Cập nhật',
                    onTap: () => _openEditMedicalHistorySheet(activeProfile),
                  ),
                  child: Column(
                    children: [
                      // Khung Lưu ý đặc biệt nổi bật
                      SpecialHistoryNoticeCard(
                        customNote: _specialHistoryNote,
                        allergies: activeProfile.allergies
                            .map((a) => a.title)
                            .toList(),
                        chronicConditions: activeProfile.chronicConditions
                            .map((c) => c.title)
                            .toList(),
                        onSaveNote: _saveSpecialNote,
                      ),
                      const SizedBox(height: 16),

                      // Thẻ Tiền sử bệnh nền & Dị ứng từ trước đến giờ
                      SeniorCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HistoryGroupBlock(
                              icon: Icons.coronavirus_rounded,
                              iconColor: AppColors.iceDangerText,
                              title: 'Tiền sử dị ứng thuốc / thực phẩm',
                              items: activeProfile.allergies
                                  .map((a) => a.title)
                                  .toList(),
                              emptyText: 'Không có ghi nhận dị ứng thuốc hay thức ăn.',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Divider(height: 1),
                            ),
                            _HistoryGroupBlock(
                              icon: Icons.medical_information_rounded,
                              iconColor: AppColors.primary,
                              title: 'Bệnh lý nền mạn tính từ trước đến nay',
                              items: activeProfile.chronicConditions
                                  .map((c) => c.title)
                                  .toList(),
                              emptyText: 'Chưa khai báo bệnh nền mạn tính.',
                            ),
                            if (activeProfile.immunizations.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1),
                              ),
                              _HistoryGroupBlock(
                                icon: Icons.vaccines_rounded,
                                iconColor: SeniorTokens.callActionGreen,
                                title: 'Lịch sử tiêm chủng đã ghi nhận',
                                items: activeProfile.immunizations
                                    .map((i) => '${i.title} (${i.subtitle})')
                                    .toList(),
                                emptyText: '',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // =============================================================
                // PHẦN (3): DÒNG THỜI GIAN BỆNH ÁN (MỚI ĐẾN CŨ)
                // =============================================================
                SeniorSectionBlock(
                  title: '3. Dòng thời gian bệnh án',
                  subtitle: 'Sắp xếp từ lần khám mới nhất đến cũ nhất',
                  icon: Icons.history_edu_rounded,
                  iconColor: AppColors.timelineOlive,
                  bottomSpacing: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SeniorActionButton(
                        label: 'Thêm hồ sơ đợt khám mới',
                        icon: Icons.add_circle_rounded,
                        variant: SeniorButtonVariant.primary,
                        onPressed: () async {
                          final added = await Navigator.pushNamed(
                            context,
                            AppRoutes.addRecord,
                          );
                          if (added == true) {
                            _timelineVm.loadRecords();
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ô tìm kiếm bệnh án chữ lớn
                      TextField(
                        controller: _timelineVm.searchController,
                        onChanged: _timelineVm.updateSearchQuery,
                        style: const TextStyle(fontSize: 17),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 28,
                            color: AppColors.primary,
                          ),
                          hintText: 'Tìm theo tên bệnh, bệnh viện, bác sĩ...',
                          hintStyle: const TextStyle(fontSize: 16),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.iceCardBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.iceCardBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Hàng bộ lọc lớn dễ chạm
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tState.filters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final f = tState.filters[idx];
                            final selected = f.id == tState.selectedFilterId;
                            return ChoiceChip(
                              selected: selected,
                              onSelected: (_) => _timelineVm.selectFilter(f.id),
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              label: Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.iceTextNavy,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTimelineList(
                        records,
                        hasAnyRecord: tState.records.isNotEmpty,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineList(
    List<TimelineRecordItem> records, {
    required bool hasAnyRecord,
  }) {
    if (records.isEmpty) {
      return SeniorCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Icon(
              hasAnyRecord
                  ? Icons.search_off_rounded
                  : Icons.folder_open_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasAnyRecord
                  ? 'Không tìm thấy bệnh án khớp bộ lọc'
                  : 'Chưa có đợt khám nào trong dòng thời gian',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                color: AppColors.iceTextNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyRecord
                  ? 'Bấm nút bên dưới để hiển thị lại toàn bộ hồ sơ bệnh án.'
                  : 'Hãy bấm "Thêm hồ sơ đợt khám mới" để lưu chẩn đoán, đơn thuốc và ảnh xét nghiệm.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.iceTextSlate,
                height: 1.4,
              ),
            ),
            if (hasAnyRecord) ...[
              const SizedBox(height: 16),
              SeniorActionButton(
                label: 'Xem lại tất cả bệnh án',
                icon: Icons.filter_alt_off_rounded,
                variant: SeniorButtonVariant.secondaryOutline,
                onPressed: () {
                  _timelineVm.searchController.clear();
                  _timelineVm.updateSearchQuery('');
                  _timelineVm.selectFilter('all');
                },
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < records.length; i++) ...[
          if (i == 0 || records[i].year != records[i - 1].year) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPeach,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Năm ${records[i].year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.timelineBadgeBrown,
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: TimelineRecordCard(
              record: records[i],
              onOpenDetail: () async {
                final res = await Navigator.pushNamed(
                  context,
                  AppRoutes.recordDetail,
                  arguments: records[i].id,
                );
                if (res == true) {
                  _timelineVm.loadRecords();
                }
              },
              onViewAllDocs: () =>
                  Navigator.pushNamed(context, AppRoutes.documents),
              onViewPrescription: () =>
                  Navigator.pushNamed(context, AppRoutes.prescriptions),
            ),
          ),
          if (i < records.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _VitalMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accent;

  const _VitalMetricBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.iceTextNavy,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryGroupBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;
  final String emptyText;

  const _HistoryGroupBlock({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.iceTextNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.iceTextSlate,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (text) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
