import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../domain/entities/prescription.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
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
        description: 'Đau âm ỉ vùng thượng vị sau ăn, ợ chua nhiều về đêm. Xét nghiệm vi khuẩn HP dương tính.',
        date: DateTime(2024, 4, 18, 9, 30),
        type: MedicalEventType.generalCheckup,
        facilityName: 'Bệnh viện Đa khoa Quốc tế Vinmec Central Park',
        doctorName: 'BS. Trần Văn Hùng',
        department: 'Khoa Tiêu hóa - Gan mật • Phòng khám VIP 3',
        diagnosis: 'Viêm dạ dày & Trào ngược dạ dày thực quản (GERD Độ A)',
        bloodPressure: '120/78',
        heartRate: '72',
        prescription: Prescription(
          id: 'RX-2024-089',
          doctorName: 'BS. Trần Văn Hùng',
          hospital: 'Bệnh viện Đa khoa Quốc tế Vinmec Central Park',
          issuedDate: DateTime(2024, 4, 18),
          medicines: const [
            Medicine(id: 'm1', name: 'Nexium Mups 40mg', dosage: '40mg • 1 viên/ngày', frequency: 'Trước ăn sáng 30p'),
            Medicine(id: 'm2', name: 'Amoxicillin 500mg', dosage: '500mg • 2 viên/ngày', frequency: 'Sau ăn no'),
            Medicine(id: 'm3', name: 'Clarithromycin 500mg', dosage: '500mg • 2 viên/ngày', frequency: 'Sau ăn no'),
            Medicine(id: 'm4', name: 'Gaviscon Dual Action', dosage: '1 gói • 3 lần/ngày', frequency: 'Sau ăn trưa/tối'),
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

  Future<void> _exportPdf(BuildContext context) async {
    final pdfService = widget.pdfReportService ??
        (sl.isRegistered<PdfReportService>() ? sl<PdfReportService>() : PdfReportServiceImpl());
    try {
      await pdfService.printRecord(record: _event);
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
        (sl.isRegistered<PdfReportService>() ? sl<PdfReportService>() : PdfReportServiceImpl());
    try {
      await pdfService.shareRecordPdf(record: _event);
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
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa hồ sơ đợt khám này? Hành động này sẽ xóa dữ liệu và không thể hoàn tác.',
          style: TextStyle(color: AppColors.iceTextSlate, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.iceTextSlate)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        SnackBar(content: Text('Không thể xóa đợt khám: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showImagePreview(BuildContext context, String title, String imagePath) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      icon: const Icon(Icons.close, color: AppColors.iceTextMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: isAsset
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _buildImageError(),
                      )
                    : (file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => _buildImageError(),
                          )
                        : _buildImageError()),
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
      child: const Icon(Icons.image_not_supported, size: 48, color: AppColors.iceTextMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF8F5),
        body: Center(child: CircularProgressIndicator(color: AppColors.iceOlive)),
      );
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final medicines = _event.prescription?.medicines ?? [];
    final attachments = _event.attachments;

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
                right: 8,
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
                      children: [
                        const Text(
                          'SỔ TAY Y TẾ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.55,
                            color: AppColors.iceOlive,
                            height: 1.1,
                          ),
                        ),
                        const Text(
                          'Chi Tiết Bệnh Án',
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
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.iceOlive),
                    tooltip: 'Chỉnh sửa đợt khám',
                    onPressed: _onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: 'Xóa đợt khám',
                    onPressed: _onDelete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20, color: AppColors.iceOlive),
                    onPressed: () => _sharePdf(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 20, color: AppColors.iceOlive),
                    onPressed: () => _exportPdf(context),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottomPadding),
                children: [
                  // 1. Patient & Code Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.iceOlive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.iceOlive.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.iceOlive.withValues(alpha: 0.2),
                                child: const Icon(Icons.person, color: AppColors.iceOliveDark, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _event.title,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Ngày khám: ${_event.date.day.toString().padLeft(2, '0')}/${_event.date.month.toString().padLeft(2, '0')}/${_event.date.year}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.iceCardBorder),
                          ),
                          child: Text(
                            '#${_event.id.toUpperCase()}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.iceOlive),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Hospital & Doctor Info Card
                  _buildSectionCard(
                    title: 'Cơ Sở Khám & Bác Sĩ Điều Trị',
                    icon: Icons.local_hospital_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_event.facilityName != null && _event.facilityName!.isNotEmpty)
                              ? _event.facilityName!
                              : 'Chưa cập nhật cơ sở khám',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                        ),
                        if (_event.department != null && _event.department!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _event.department!,
                            style: const TextStyle(fontSize: 13, color: AppColors.iceTextSlate),
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.iceCardBorder),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surfaceWarm,
                              child: Icon(Icons.medical_services_outlined, size: 18, color: AppColors.iceOlive),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _event.doctorName != null && _event.doctorName!.isNotEmpty
                                        ? (_event.doctorName!.startsWith('BS') ? _event.doctorName! : 'BS. ${_event.doctorName}')
                                        : 'Chưa cập nhật bác sĩ điều trị',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                                  ),
                                  const Text(
                                    'Bác sĩ điều trị chuyên khoa',
                                    style: TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Clinical Diagnosis & Description
                  _buildSectionCard(
                    title: 'Chẩn Đoán Lâm Sàng & Diễn Tiến',
                    icon: Icons.health_and_safety_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _event.diagnosis ?? _event.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.iceOliveDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _event.description ?? 'Đau âm ỉ thượng vị, ợ hơi nhẹ sau ăn.',
                          style: const TextStyle(fontSize: 13, color: AppColors.iceTextSlate, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Recorded Vitals Bento
                  _buildSectionCard(
                    title: 'Chỉ Số Sinh Hiệu Đo Lúc Khám',
                    icon: Icons.monitor_heart_outlined,
                    child: Row(
                      children: [
                        _buildVitalPill('Huyết áp', _event.bloodPressure ?? '120/78', 'mmHg', true),
                        const SizedBox(width: 8),
                        _buildVitalPill('Nhịp tim', _event.heartRate ?? '72', 'bpm', true),
                        const SizedBox(width: 8),
                        _buildVitalPill('SpO2', '98', '%', true),
                        const SizedBox(width: 8),
                        _buildVitalPill('Nhiệt độ', '36.8', '°C', true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Attached Clinical Files (with tap-to-zoom)
                  _buildSectionCard(
                    title: 'Tài Liệu & Kết Quả Cận Lâm Sàng (${attachments.length})',
                    icon: Icons.folder_open_outlined,
                    child: attachments.isEmpty
                        ? const Text('Chưa có tài liệu đính kèm.', style: TextStyle(color: AppColors.iceTextMuted, fontSize: 13))
                        : Column(
                            children: [
                              for (int i = 0; i < attachments.length; i++) ...[
                                _buildAttachmentRow(
                                  context: context,
                                  title: attachments[i].split('/').last,
                                  subtitle: 'Ảnh tài liệu đính kèm',
                                  imagePath: attachments[i],
                                ),
                                if (i < attachments.length - 1) const SizedBox(height: 8),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Prescriptions Card
                  _buildSectionCard(
                    title: 'Toa Thuốc Điều Trị Ngoại Trú (14 Ngày)',
                    icon: Icons.medication_outlined,
                    child: medicines.isEmpty
                        ? const Text('Chưa có toa thuốc chỉ định cho đợt khám này.', style: TextStyle(color: AppColors.iceTextMuted, fontSize: 13))
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
                                if (i < medicines.length - 1) const Divider(height: 16, color: AppColors.iceCardBorder),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),

                  // Bottom Action Buttons: Edit and Export
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Chỉnh Sửa'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.iceOlive,
                            side: const BorderSide(color: AppColors.iceOlive),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportPdf(context),
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Xuất Bản PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.iceOlive,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildVitalPill(String label, String value, String unit, bool isNormal) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.iceCardBorder),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.iceTextSlate),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(fontSize: 9, color: AppColors.iceTextMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          border: Border.all(color: AppColors.iceCardBorder),
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
                    ? Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined))
                    : (file.existsSync()
                        ? Image.file(file, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined))
                        : const Icon(Icons.image_outlined, color: AppColors.iceOlive)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.iceTextMuted),
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
          radius: 11,
          backgroundColor: AppColors.iceOlive.withValues(alpha: 0.15),
          child: Text(
            stt,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.iceOliveDark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
              ),
              const SizedBox(height: 2),
              Text(
                dosage,
                style: const TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
              ),
              const SizedBox(height: 2),
              Text(
                duration,
                style: const TextStyle(fontSize: 11, color: AppColors.iceOlive, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
