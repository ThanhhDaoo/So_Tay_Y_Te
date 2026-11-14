import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/entities/medicine.dart';
import '../../../../domain/entities/prescription.dart';
import '../../../routes/app_routes.dart';

class RecordDetailScreen extends StatelessWidget {
  final String recordId;
  final PdfReportService? pdfReportService;

  const RecordDetailScreen({
    super.key,
    required this.recordId,
    this.pdfReportService,
  });

  MedicalEvent _createCurrentEvent() {
    return MedicalEvent(
      id: recordId.isNotEmpty ? recordId : 'REC-2024-0418',
      title: 'Viêm dạ dày & Trào ngược dạ dày thực quản (GERD Độ A)',
      description: 'Đau âm ỉ vùng thượng vị sau ăn, ợ chua nhiều về đêm. Xét nghiệm vi khuẩn HP dương tính.',
      date: DateTime(2024, 4, 18, 9, 30),
      type: MedicalEventType.generalCheckup,
      prescription: Prescription(
        id: 'RX-2024-089',
        doctorName: 'BS. CKII Lê Hoàng Tuấn',
        hospital: 'Bệnh viện Đa khoa Quốc tế Vinmec',
        issuedDate: DateTime(2024, 4, 18),
        medicines: const [
          Medicine(id: 'm1', name: 'Nexium Mups 40mg', dosage: '40mg • 1 viên/ngày', frequency: 'Trước ăn sáng 30p'),
          Medicine(id: 'm2', name: 'Amoxicillin 500mg', dosage: '500mg • 2 viên/ngày', frequency: 'Sau ăn no'),
          Medicine(id: 'm3', name: 'Clarithromycin 500mg', dosage: '500mg • 2 viên/ngày', frequency: 'Sau ăn no'),
          Medicine(id: 'm4', name: 'Gaviscon Dual Action', dosage: '1 gói • 3 lần/ngày', frequency: 'Sau ăn trưa/tối'),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final pdfService = pdfReportService ??
        (sl.isRegistered<PdfReportService>() ? sl<PdfReportService>() : PdfReportServiceImpl());
    try {
      final event = _createCurrentEvent();
      await pdfService.printRecord(record: event);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất PDF: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final pdfService = pdfReportService ??
        (sl.isRegistered<PdfReportService>() ? sl<PdfReportService>() : PdfReportServiceImpl());
    try {
      final event = _createCurrentEvent();
      await pdfService.shareRecordPdf(record: event);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chia sẻ PDF: $e')),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context, String title, String imageAsset) {
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
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: AppColors.surfaceWarm,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, size: 48, color: AppColors.iceTextMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

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
                right: 16,
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
                    icon: const Icon(Icons.share_outlined, size: 22, color: AppColors.iceOlive),
                    onPressed: () => _sharePdf(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 22, color: AppColors.iceOlive),
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.iceOlive.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: AppColors.iceOliveDark, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Nguyễn Thu Trang',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                                ),
                                Text(
                                  '32 tuổi • Nhóm máu O+ • Nữ',
                                  style: TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.iceCardBorder),
                          ),
                          child: Text(
                            recordId.isNotEmpty ? '#${recordId.toUpperCase()}' : '#REC-2024-0418',
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
                        const Text(
                          'Bệnh viện Đa khoa Quốc tế Vinmec Central Park',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Khoa Tiêu hóa - Gan mật • Phòng khám VIP 3',
                          style: TextStyle(fontSize: 13, color: AppColors.iceTextSlate),
                        ),
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
                                children: const [
                                  Text(
                                    'BS. Trần Văn Hùng',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                                  ),
                                  Text(
                                    'Bác sĩ Chuyên khoa II • Chứng chỉ hành nghề: 018492/HCM',
                                    style: TextStyle(fontSize: 11, color: AppColors.iceTextSlate),
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

                  // 3. Clinical Diagnosis Card
                  _buildSectionCard(
                    title: 'Chẩn Đoán Lâm Sàng & Triệu Chứng',
                    icon: Icons.biotech_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8E8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ICD-10: K29.5 · Viêm dạ dày mạn tính, HP (+)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9B1C1C)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Triệu chứng khai báo:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Đau tức vùng thượng vị âm ỉ liên tục 2 tuần, ợ chua, buồn nôn nhẹ sau khi ăn đồ cay nóng hoặc thức khuya. Không sụt cân, không nôn ra máu.',
                          style: TextStyle(fontSize: 13, color: AppColors.iceTextSlate, height: 1.35),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Kết luận nội soi:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Niêm mạc hang vị phù nề, rải rác có vài ổ trợt nông đường kính 2-3mm. Môn vị co bóp tốt, không hẹp. Clo-test xác định vi khuẩn Helicobacter Pylori dương tính (++).',
                          style: TextStyle(fontSize: 13, color: AppColors.iceTextSlate, height: 1.35),
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
                        _buildVitalPill('Huyết áp', '120/78', 'mmHg', true),
                        const SizedBox(width: 8),
                        _buildVitalPill('Nhịp tim', '72', 'bpm', true),
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
                    title: 'Tài Liệu & Kết Quả Cận Lâm Sàng (3)',
                    icon: Icons.folder_open_outlined,
                    child: Column(
                      children: [
                        _buildAttachmentRow(
                          context: context,
                          title: 'Ảnh chụp nội soi dạ dày HP (+)',
                          subtitle: 'Tệp hình ảnh JPEG · 2.4 MB · 18/04/2024',
                          imageAsset: 'assets/images/img_doc_endoscopy.png',
                        ),
                        const SizedBox(height: 8),
                        _buildAttachmentRow(
                          context: context,
                          title: 'Xét nghiệm huyết học tổng quát (CBC)',
                          subtitle: 'Bản quét PDF/OCR · 1.1 MB · 18/04/2024',
                          imageAsset: 'assets/images/img_doc_blood_test.png',
                        ),
                        const SizedBox(height: 8),
                        _buildAttachmentRow(
                          context: context,
                          title: 'X-Quang ngực thẳng kỹ thuật số',
                          subtitle: 'Chẩn đoán hình ảnh DICOM/PNG · 3.8 MB',
                          imageAsset: 'assets/images/img_doc_xray.png',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. Prescriptions Card
                  _buildSectionCard(
                    title: 'Toa Thuốc Điều Trị Ngoại Trú (14 Ngày)',
                    icon: Icons.medication_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMedicationItem(
                          stt: '1',
                          name: 'Nexium 40mg (Esomeprazole)',
                          dosage: '1 viên/lần · Ngày 1 lần (Trước ăn sáng 30 phút)',
                          duration: 'Số lượng: 14 viên',
                        ),
                        const Divider(height: 16, color: AppColors.iceCardBorder),
                        _buildMedicationItem(
                          stt: '2',
                          name: 'Amoxicillin 500mg (Kháng sinh)',
                          dosage: '2 viên/lần · Ngày 2 lần (Sau ăn sáng và tối)',
                          duration: 'Số lượng: 56 viên',
                        ),
                        const Divider(height: 16, color: AppColors.iceCardBorder),
                        _buildMedicationItem(
                          stt: '3',
                          name: 'Clarithromycin 500mg',
                          dosage: '1 viên/lần · Ngày 2 lần (Sau ăn sáng và tối)',
                          duration: 'Số lượng: 28 viên',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 7. Doctor Advice & Next Appointment
                  _buildSectionCard(
                    title: 'Lời Dặn Bác Sĩ & Lịch Tái Khám',
                    icon: Icons.event_available_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• Uống thuốc đều đặn đúng giờ, tuyệt đối không ngưng kháng sinh giữa chừng để tránh tình trạng kháng thuốc HP.',
                          style: TextStyle(fontSize: 13, color: AppColors.iceTextSlate, height: 1.35),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '• Kiêng đồ ăn cay, chua, cà phê, rượu bia, thức khuya.',
                          style: TextStyle(fontSize: 13, color: AppColors.iceTextSlate, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.iceAccentCream),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.calendar_month, color: AppColors.iceOlive, size: 24),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hẹn tái khám & Test hơi thở C13',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                                    ),
                                    Text(
                                      '08:30 Sáng - Thứ Năm, 16/05/2024 (Sau 4 tuần)',
                                      style: TextStyle(fontSize: 12, color: AppColors.iceOliveDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.prescriptions),
                          icon: const Icon(Icons.alarm_on, size: 18),
                          label: const Text('Xem Lịch Thuốc'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.iceOliveDark,
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.iceCardBorder),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.iceTextMuted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy)),
            Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.iceTextSlate)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imageAsset,
  }) {
    return InkWell(
      onTap: () => _showImagePreview(context, title, imageAsset),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.iceCardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageAsset,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 20, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                    style: const TextStyle(fontSize: 11, color: AppColors.iceTextSlate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.zoom_in, color: AppColors.iceOlive, size: 20),
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
          backgroundColor: AppColors.iceOlive.withValues(alpha: 0.12),
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
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.iceOliveDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
