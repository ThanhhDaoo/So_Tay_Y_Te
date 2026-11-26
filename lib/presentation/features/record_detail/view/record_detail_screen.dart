import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../domain/entities/prescription.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../add_record/view/add_record_screen.dart';

class RecordDetailScreen extends StatefulWidget {
  final String recordId;
  final PdfReportService? pdfReportService;
  final MedicalRecordRepository? repository;

  const RecordDetailScreen({
    super.key,
    required this.recordId,
    this.pdfReportService,
    this.repository,
  });

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  late MedicalEvent _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  MedicalEvent _createFallbackEvent() {
    if (widget.recordId == 'REC-2024-0418' || widget.recordId == 'sample') {
      return MedicalEvent(
        id: 'REC-2024-0418',
        title: 'Viêm dạ dày & Trào ngược dạ dày thực quản (GERD Độ A)',
        description:
            'Đau âm ỉ vùng thượng vị sau ăn, ợ chua nhiều về đêm. Xét nghiệm vi khuẩn HP dương tính.',
        date: DateTime(2024, 4, 18, 9, 30),
        type: MedicalEventType.generalCheckup,
        facilityName: 'Bệnh viện Đa khoa Quốc tế Vinmec Central Park',
        doctorName: 'BS. Trần Văn Hùng',
        department: 'Khoa Tiêu hóa - Gan mật • Phòng khám VIP 3',
        diagnosis: 'Viêm dạ dày & Trào ngược dạ dày thực quản (GERD Độ A)',
        bloodPressure: '120/78',
        heartRate: '72',
        spo2: '98',
        temperature: '36.8',
        prescription: Prescription(
          id: 'RX-2024-089',
          doctorName: 'BS. Trần Văn Hùng',
          hospital: 'Bệnh viện Đa khoa Quốc tế Vinmec Central Park',
          issuedDate: DateTime(2024, 4, 18),
          durationDays: 14,
          medicines: const [
            Medicine(
              id: 'm1',
              name: 'Nexium Mups 40mg',
              dosage: '40mg • 1 viên/ngày',
              frequency: 'Trước ăn sáng 30p',
            ),
            Medicine(
              id: 'm2',
              name: 'Amoxicillin 500mg',
              dosage: '500mg • 2 viên/ngày',
              frequency: 'Sau ăn no',
            ),
            Medicine(
              id: 'm3',
              name: 'Clarithromycin 500mg',
              dosage: '500mg • 2 viên/ngày',
              frequency: 'Sau ăn no',
            ),
            Medicine(
              id: 'm4',
              name: 'Gaviscon Dual Action',
              dosage: '1 gói • 3 lần/ngày',
              frequency: 'Sau ăn trưa/tối',
            ),
          ],
        ),
        attachments: const [
          'assets/images/img_doc_endoscopy.png',
          'assets/images/img_doc_blood_test.png',
          'assets/images/img_doc_xray.png',
        ],
      );
    }
    return MedicalEvent(
      id: widget.recordId.isNotEmpty ? widget.recordId : 'REC-CHUA-CO',
      title: 'Hồ sơ đợt khám',
      description: 'Chưa có thông tin diễn tiến bệnh.',
      date: DateTime.now(),
      type: MedicalEventType.generalCheckup,
      facilityName: 'Chưa cập nhật cơ sở khám',
      doctorName: 'Chưa cập nhật bác sĩ',
      department: 'Khám tổng quát',
      diagnosis: 'Chưa cập nhật chẩn đoán',
      bloodPressure: null,
      heartRate: null,
      prescription: null,
      attachments: const [],
    );
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final repo = widget.repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null && widget.recordId.isNotEmpty) {
        final loaded = await repo.getMedicalEventById(widget.recordId);
        if (loaded != null) {
          setState(() {
            _event = loaded;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _event = _createFallbackEvent();
      _isLoading = false;
    });
  }

  Future<UserProfile?> _loadCurrentPatientProfile() async {
    if (!sl.isRegistered<AuthRepository>()) return null;
    try {
      final authRepo = sl<AuthRepository>();
      final session = await authRepo.getActiveSession();
      if (session == null) {
        return await authRepo.getCurrentUser();
      }
      final details = await authRepo.getUserProfileDetails(session.id);
      final rawAllergies = details?['allergies']?.toString().trim() ?? '';
      final rawConditions =
          details?['chronic_conditions']?.toString().trim() ?? '';
      final allergyList = rawAllergies.isNotEmpty
          ? rawAllergies
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const <String>[];
      final conditionList = rawConditions.isNotEmpty
          ? rawConditions
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const <String>[];
      final emergency = details?['emergency_contact']?.toString().trim();

      return UserProfile(
        id: session.id,
        fullName: session.fullName,
        dateOfBirth: session.dateOfBirth != null
            ? DateTime.tryParse(session.dateOfBirth!)
            : null,
        bloodType: session.bloodType,
        allergies: allergyList,
        chronicConditions: conditionList,
        emergencyContact: (emergency != null &&
                emergency.isNotEmpty &&
                !emergency.contains('@'))
            ? emergency
            : (!session.primaryContact.contains('@')
                ? session.primaryContact
                : null),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final pdfService = widget.pdfReportService ??
        (sl.isRegistered<PdfReportService>()
            ? sl<PdfReportService>()
            : PdfReportServiceImpl());
    try {
      final profile = await _loadCurrentPatientProfile();
      await pdfService.printRecord(record: _event, patientProfile: profile);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất PDF: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final pdfService = widget.pdfReportService ??
        (sl.isRegistered<PdfReportService>()
            ? sl<PdfReportService>()
            : PdfReportServiceImpl());
    try {
      final profile = await _loadCurrentPatientProfile();
      await pdfService.shareRecordPdf(record: _event, patientProfile: profile);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chia sẻ PDF: $e')),
        );
      }
    }
  }

  Future<void> _onEdit() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(recordToEdit: _event),
      ),
    );
    if (res == true) {
      _loadEvent();
    }
  }

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác Nhận Xóa Bệnh Án',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.iceTextNavy,
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa hồ sơ đợt khám này? Hành động này sẽ xóa dữ liệu và không thể hoàn tác.',
          style: TextStyle(color: AppColors.iceTextSlate, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.iceTextSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = widget.repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null) {
        await repo.deleteMedicalEvent(_event.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thành công đợt khám khỏi sổ y tế.'),
          backgroundColor: AppColors.iceOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa đợt khám: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImagePreview(
    BuildContext context,
    String title,
    String imagePath,
  ) {
    final isAsset = imagePath.startsWith('assets/');
    final file = File(imagePath);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.iceTextMuted,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: InteractiveViewer(
                  minScale: 0.9,
                  maxScale: 3.0,
                  child: isAsset
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImageError(),
                        )
                      : (file.existsSync()
                          ? Image.file(
                              file,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImageError(),
                            )
                          : _buildImageError()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 220,
      color: AppColors.surfaceWarm,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: AppColors.iceTextMuted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.iceBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.iceOlive),
        ),
      );
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final medicines = _event.prescription?.medicines ?? [];
    final attachments = _event.attachments;
    final formattedDate =
        '${_event.date.day.toString().padLeft(2, '0')}/${_event.date.month.toString().padLeft(2, '0')}/${_event.date.year}';
    final doctorLabel =
        _event.doctorName != null && _event.doctorName!.isNotEmpty
            ? (_event.doctorName!.startsWith('BS')
                ? _event.doctorName!
                : 'BS. ${_event.doctorName}')
            : 'Chưa cập nhật bác sĩ';

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header gọn thoáng: gom Sửa/Xóa vào menu ⋮ để nhường chỗ cho tiêu đề
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 8,
                bottom: 12,
                left: 10,
                right: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.iceCardBorder.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppColors.iceTextNavy,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          'Chi Tiết Bệnh Án',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: AppColors.iceOlive,
                    ),
                    tooltip: 'Chia sẻ PDF',
                    onPressed: () => _sharePdf(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 20,
                      color: AppColors.iceOlive,
                    ),
                    tooltip: 'Xuất PDF',
                    onPressed: () => _exportPdf(context),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AppColors.iceTextNavy,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (val) {
                      if (val == 'edit') _onEdit();
                      if (val == 'delete') _onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.iceOlive,
                            ),
                            SizedBox(width: 10),
                            Text('Chỉnh sửa đợt khám'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Xóa đợt khám',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content List với khoảng thở chuẩn 24px
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppLayoutTokens.screenPadding,
                  20,
                  AppLayoutTokens.screenPadding,
                  32 + bottomPadding,
                ),
                children: [
                  // Cụm 1: Thẻ Tổng quan Đợt khám & Cơ sở điều trị (hợp nhất gọn gàng, không lồng Divider)
                  CleanCard(
                    padding: const EdgeInsets.all(
                      AppLayoutTokens.heroCardPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ngày khám: $formattedDate',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.iceOlive,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWarm,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${_event.id.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.iceTextSlate,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _event.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        KeyValueRow(
                          label: 'Cơ sở y tế',
                          value: (_event.facilityName != null &&
                                  _event.facilityName!.isNotEmpty)
                              ? _event.facilityName!
                              : 'Chưa cập nhật cơ sở khám',
                        ),
                        if (_event.department != null &&
                            _event.department!.isNotEmpty)
                          KeyValueRow(
                            label: 'Chuyên khoa',
                            value: _event.department!,
                          ),
                        KeyValueRow(
                          label: 'Bác sĩ điều trị',
                          value: doctorLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppLayoutTokens.sectionGap),

                  // Cụm 2: Chẩn đoán lâm sàng & Diễn tiến
                  SectionContainer(
                    title: 'Chẩn Đoán & Diễn Tiến Lâm Sàng',
                    icon: Icons.health_and_safety_outlined,
                    bottomSpacing: AppLayoutTokens.sectionGap,
                    child: CleanCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_event.diagnosis != null &&
                                    _event.diagnosis!.trim().isNotEmpty)
                                ? _event.diagnosis!.trim()
                                : _event.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iceOliveDark,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_event.description != null &&
                                    _event.description!.trim().isNotEmpty)
                                ? _event.description!.trim()
                                : 'Chưa có ghi chú triệu chứng / diễn tiến lâm sàng.',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.iceTextSlate,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cụm 3: Chỉ số sinh hiệu lưới 2x2 dễ đọc (thay dãy 4 ô ép ngang chữ 9px)
                  SectionContainer(
                    title: 'Chỉ Số Sinh Hiệu Đo Lúc Khám',
                    icon: Icons.monitor_heart_outlined,
                    bottomSpacing: AppLayoutTokens.sectionGap,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildVitalTile(
                                label: 'Huyết áp',
                                value: (_event.bloodPressure != null &&
                                        _event.bloodPressure!.trim().isNotEmpty)
                                    ? _event.bloodPressure!.trim()
                                    : '--',
                                unit: 'mmHg',
                              ),
                            ),
                            const SizedBox(width: AppLayoutTokens.cardGap),
                            Expanded(
                              child: _buildVitalTile(
                                label: 'Nhịp tim',
                                value: (_event.heartRate != null &&
                                        _event.heartRate!.trim().isNotEmpty)
                                    ? _event.heartRate!.trim()
                                    : '--',
                                unit: 'bpm',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayoutTokens.cardGap),
                        Row(
                          children: [
                            Expanded(
                              child: _buildVitalTile(
                                label: 'SpO2 (Oxy máu)',
                                value: (_event.spo2 != null &&
                                        _event.spo2!.trim().isNotEmpty)
                                    ? _event.spo2!.trim()
                                    : '--',
                                unit: '%',
                              ),
                            ),
                            const SizedBox(width: AppLayoutTokens.cardGap),
                            Expanded(
                              child: _buildVitalTile(
                                label: 'Nhiệt độ cơ thể',
                                value: (_event.temperature != null &&
                                        _event.temperature!.trim().isNotEmpty)
                                    ? _event.temperature!.trim()
                                    : '--',
                                unit: '°C',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Cụm 4: Toa thuốc điều trị ngoại trú
                  SectionContainer(
                    title: _event.prescription?.durationDays != null
                        ? 'Toa Thuốc Điều Trị Ngoại Trú (${_event.prescription!.durationDays} Ngày)'
                        : 'Toa Thuốc Điều Trị Ngoại Trú',
                    icon: Icons.medication_outlined,
                    bottomSpacing: AppLayoutTokens.sectionGap,
                    child: CleanCard(
                      child: medicines.isEmpty
                          ? const Text(
                              'Chưa có toa thuốc chỉ định cho đợt khám này.',
                              style: TextStyle(
                                color: AppColors.iceTextMuted,
                                fontSize: 13.5,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < medicines.length; i++) ...[
                                  _buildMedicationItem(
                                    stt: '${i + 1}',
                                    name: medicines[i].name,
                                    dosage: medicines[i].dosage,
                                    duration: medicines[i].frequency,
                                  ),
                                  if (i < medicines.length - 1)
                                    const SizedBox(height: 14),
                                ],
                              ],
                            ),
                    ),
                  ),

                  // Cụm 5: Tài liệu & Kết quả cận lâm sàng
                  SectionContainer(
                    title:
                        'Tài Liệu & Kết Quả Cận Lâm Sàng (${attachments.length})',
                    icon: Icons.folder_open_outlined,
                    bottomSpacing: 28,
                    child: CleanCard(
                      child: attachments.isEmpty
                          ? const Text(
                              'Chưa có tài liệu đính kèm.',
                              style: TextStyle(
                                color: AppColors.iceTextMuted,
                                fontSize: 13.5,
                              ),
                            )
                          : Column(
                              children: [
                                for (int i = 0;
                                    i < attachments.length;
                                    i++) ...[
                                  _buildAttachmentRow(
                                    context: context,
                                    title: attachments[i].split('/').last,
                                    subtitle: 'Chạm để phóng to hình ảnh',
                                    imagePath: attachments[i],
                                  ),
                                  if (i < attachments.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                    ),
                  ),

                  // Nút hành động chính ở cuối trang
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(
                            'Chỉnh Sửa',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.iceOlive,
                            side: const BorderSide(color: AppColors.iceOlive),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppLayoutTokens.cardGap),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportPdf(context),
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text(
                            'Xuất Bản PDF',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.iceOlive,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalTile({
    required String label,
    required String value,
    required String unit,
  }) {
    final hasValue = value != '--';
    return CleanCard(
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.iceTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: hasValue
                      ? AppColors.iceTextNavy
                      : AppColors.iceTextMuted,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    final isAsset = imagePath.startsWith('assets/');
    final file = File(imagePath);

    return InkWell(
      onTap: () => _showImagePreview(context, title, imagePath),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.white,
                child: isAsset
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_outlined),
                      )
                    : (file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_outlined),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: AppColors.iceOlive,
                          )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iceTextNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.iceTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.zoom_in, size: 20, color: AppColors.iceOlive),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem({
    required String stt,
    required String name,
    required String dosage,
    required String duration,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.iceOlive.withValues(alpha: 0.14),
          child: Text(
            stt,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.iceOliveDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceTextNavy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$dosage • $duration',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.iceTextSlate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
