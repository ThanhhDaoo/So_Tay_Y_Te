import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/doctor_contact.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../viewmodel/doctors_viewmodel.dart';
import 'widgets/add_edit_doctor_sheet.dart';

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
            content: Text(msg, style: const TextStyle(fontSize: 15.5)),
            backgroundColor: AppColors.iceOlive,
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
        backgroundColor: AppColors.iceBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Xóa bác sĩ khỏi danh bạ?',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xóa thông tin ${doc.fullName} không?',
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Giữ lại',
              style: TextStyle(fontSize: 16, color: AppColors.iceTextSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.iceDangerText,
              foregroundColor: Colors.white,
              minimumSize: const Size(96, 46),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xóa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final doctors = _viewModel.doctors;

        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBodyBehindAppBar: true,
          appBar: MedVaultGlassAppBar(
            title: 'Bác Sĩ Của Tôi',
            onBack: () => Navigator.pop(context),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              AppLayoutTokens.screenPadding,
              topPad + 78,
              AppLayoutTokens.screenPadding,
              bottomPad + 40,
            ),
            children: [
              SeniorActionButton(
                label: 'Thêm bác sĩ đã khám',
                icon: Icons.person_add_alt_1_outlined,
                variant: SeniorButtonVariant.primary,
                minHeight: 54,
                onPressed: () => _openAddOrEdit(),
              ),
              const SizedBox(height: 20),

              if (_viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.iceOlive),
                  ),
                )
              else if (doctors.isEmpty)
                SeniorCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ic_doctor_bag.svg',
                        width: 36,
                        height: 36,
                        colorFilter: const ColorFilter.mode(
                          AppColors.iceOlive,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa lưu bác sĩ nào',
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bấm nút "Thêm bác sĩ đã khám" để lưu số điện thoại và lời dặn của bác sĩ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          color: AppColors.iceTextSlate,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (int i = 0; i < doctors.length; i++) ...[
                  _DoctorEditorialCard(
                    doctor: doctors[i],
                    onCallNow: () => _viewModel.callDoctorNow(doctors[i]),
                    onEdit: () => _openAddOrEdit(doctors[i]),
                    onDelete: () => _confirmDelete(doctors[i]),
                  ),
                  if (i < doctors.length - 1) const SizedBox(height: 16),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _DoctorEditorialCard extends StatelessWidget {
  final DoctorContact doctor;
  final VoidCallback onCallNow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DoctorEditorialCard({
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.iceSecondaryCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.iceBorderCream, width: 1.5),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: provider == null
          ? SvgPicture.asset(
              'assets/icons/ic_doctor_bag.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.iceOlive,
                BlendMode.srcIn,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SeniorCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (doctor.isPrimaryDoctor)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'BÁC SĨ THEO DÕI CHÍNH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.reportTeal,
                          ),
                        ),
                      ),
                    Text(
                      doctor.fullName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.iceTextNavy,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iceSecondaryCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doctor.specialty,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iceOliveDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          KeyValueRow(
            label: 'Cơ sở y tế',
            value: doctor.hospitalName,
          ),
          KeyValueRow(
            label: 'Điện thoại',
            value: doctor.phoneNumber,
            valueWeight: FontWeight.w700,
          ),

          if ((doctor.lastVisitNote != null &&
                  doctor.lastVisitNote!.trim().isNotEmpty) ||
              (doctor.lastVisitDate != null &&
                  doctor.lastVisitDate!.trim().isNotEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.iceMetricBox,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.lastVisitDate != null &&
                            doctor.lastVisitDate!.trim().isNotEmpty
                        ? 'GHI CHÚ KHÁM GẦN NHẤT (${doctor.lastVisitDate})'
                        : 'GHI CHÚ KHÁM GẦN NHẤT',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.45,
                      color: AppColors.textWarmBrown,
                    ),
                  ),
                  if (doctor.lastVisitNote != null &&
                      doctor.lastVisitNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      doctor.lastVisitNote!,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.iceTextSlate,
                        height: 1.42,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SeniorActionButton(
            label: 'Gọi ngay • ${doctor.phoneNumber}',
            icon: Icons.phone_in_talk_outlined,
            variant: SeniorButtonVariant.callNow,
            minHeight: 54,
            onPressed: onCallNow,
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SeniorLabeledIconButton(
                  icon: Icons.edit_outlined,
                  label: 'Chỉnh sửa',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              SeniorLabeledIconButton(
                icon: Icons.delete_outline_rounded,
                label: 'Xóa',
                color: AppColors.iceDangerText,
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
