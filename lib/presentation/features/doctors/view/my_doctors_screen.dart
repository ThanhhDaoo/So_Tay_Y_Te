import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/doctor_contact.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../viewmodel/doctors_viewmodel.dart';
import 'widgets/add_edit_doctor_sheet.dart';

/// Trang Danh bạ Bác sĩ đã khám ("Bác sĩ của tôi") chuẩn 40+:
/// Lưu trữ Họ tên, Ảnh đại diện, Chuyên khoa, Bệnh viện/Phòng khám, SĐT, Ghi chú lần khám gần nhất.
/// Có nút "Gọi ngay" màu nổi bật mở trình gọi điện trực tiếp & nút "Thêm bác sĩ".
class MyDoctorsScreen extends StatefulWidget {
  final DoctorsViewModel? viewModel;

  const MyDoctorsScreen({super.key, this.viewModel});

  @override
  State<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends State<MyDoctorsScreen> {
  late final DoctorsViewModel _viewModel;
  bool _ownsVm = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = DoctorsViewModel();
      _ownsVm = true;
    }
    _viewModel.addListener(_onVmChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onVmChanged);
    if (_ownsVm) _viewModel.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    final msg = _viewModel.feedbackMessage;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontSize: 16)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      _viewModel.clearFeedback();
    }
  }

  void _openAddOrEdit([DoctorContact? doctor]) {
    AddEditDoctorSheet.show(
      context,
      existing: doctor,
      onSave: _viewModel.addOrUpdateDoctor,
    );
  }

  Future<void> _confirmDelete(DoctorContact doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Xóa bác sĩ khỏi danh bạ?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Bạn có chắc muốn xóa thông tin ${doc.fullName} không?',
          style: const TextStyle(fontSize: 17, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 48),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xóa',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _viewModel.deleteDoctor(doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final doctors = _viewModel.doctors;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 146,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
              child: SeniorLabeledIconButton(
                icon: Icons.arrow_back_rounded,
                label: 'Quay lại',
                onTap: () => Navigator.pop(context),
              ),
            ),
            title: const Text(
              'Bác Sĩ Của Tôi',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.iceTextNavy,
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              AppLayoutTokens.screenPadding,
              12,
              AppLayoutTokens.screenPadding,
              bottomPad + 40,
            ),
            children: [
              // Nút lớn "Thêm bác sĩ" ở đầu trang
              SeniorActionButton(
                label: 'Thêm bác sĩ đã khám',
                icon: Icons.person_add_alt_1_rounded,
                variant: SeniorButtonVariant.primary,
                minHeight: 56,
                onPressed: () => _openAddOrEdit(),
              ),
              const SizedBox(height: SeniorTokens.sectionGap),

              if (_viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (doctors.isEmpty)
                SeniorCard(
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 52,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Chưa lưu bác sĩ nào',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hãy bấm nút "Thêm bác sĩ đã khám" để lưu số điện thoại và lời dặn của bác sĩ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.5,
                          color: AppColors.iceTextSlate,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (int i = 0; i < doctors.length; i++) ...[
                  _DoctorBigCard(
                    doctor: doctors[i],
                    onCallNow: () => _viewModel.callDoctorNow(doctors[i]),
                    onEdit: () => _openAddOrEdit(doctors[i]),
                    onDelete: () => _confirmDelete(doctors[i]),
                  ),
                  if (i < doctors.length - 1) const SizedBox(height: 20),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _DoctorBigCard extends StatelessWidget {
  final DoctorContact doctor;
  final VoidCallback onCallNow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DoctorBigCard({
    required this.doctor,
    required this.onCallNow,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildDoctorAvatar() {
    ImageProvider? provider;
    final path = doctor.avatarPath;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('assets/')) {
        provider = AssetImage(path);
      } else if (!path.startsWith('http') && File(path).existsSync()) {
        provider = FileImage(File(path));
      }
    }
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: SeniorTokens.callActionGreenSoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: SeniorTokens.callActionGreen.withValues(alpha: 0.45),
          width: 2,
        ),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      child: provider == null
          ? const Icon(
              Icons.medical_services_rounded,
              size: 36,
              color: SeniorTokens.callActionGreen,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SeniorCard(
      padding: const EdgeInsets.all(20),
      borderColor: doctor.isPrimaryDoctor
          ? SeniorTokens.callActionGreen.withValues(alpha: 0.5)
          : AppColors.iceCardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doctor.isPrimaryDoctor) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: SeniorTokens.callActionGreenSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 19,
                    color: SeniorTokens.callActionGreen,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Bác sĩ theo dõi chính',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: SeniorTokens.callActionGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.iceTextNavy,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPeach.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doctor.specialty,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bệnh viện / Phòng khám & Số điện thoại
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.local_hospital_rounded,
                size: 24,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doctor.hospitalName,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextNavy,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.phone_in_talk_rounded,
                size: 24,
                color: SeniorTokens.callActionGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Số điện thoại: ${doctor.phoneNumber}',
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.iceTextNavy,
                  ),
                ),
              ),
            ],
          ),

          // Ghi chú lần khám gần nhất
          if ((doctor.lastVisitNote != null &&
                  doctor.lastVisitNote!.trim().isNotEmpty) ||
              (doctor.lastVisitDate != null &&
                  doctor.lastVisitDate!.trim().isNotEmpty)) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.iceCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.lastVisitDate != null &&
                            doctor.lastVisitDate!.trim().isNotEmpty
                        ? 'Ghi chú lần khám gần nhất (${doctor.lastVisitDate}):'
                        : 'Ghi chú lần khám gần nhất:',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  if (doctor.lastVisitNote != null &&
                      doctor.lastVisitNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      doctor.lastVisitNote!,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.iceTextNavy,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Nút "Gọi ngay" màu xanh nổi bật
          SeniorActionButton(
            label: 'Gọi ngay (${doctor.phoneNumber})',
            icon: Icons.call_rounded,
            variant: SeniorButtonVariant.callNow,
            minHeight: 56,
            onPressed: onCallNow,
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SeniorLabeledIconButton(
                  icon: Icons.edit_rounded,
                  label: 'Sửa thông tin',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              SeniorLabeledIconButton(
                icon: Icons.delete_outline_rounded,
                label: 'Xóa',
                color: AppColors.error,
                backgroundColor: AppColors.iceDangerBg.withValues(alpha: 0.45),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
