import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/local/elder_care_local_datasource.dart';
import '../../../../data/repositories/elder_care_repository_impl.dart';
import '../../../../domain/entities/daily_vital_log.dart';
import '../../../../domain/repositories/elder_care_repository.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../../prescriptions/view/widgets/prescription_ocr_result_modal.dart';
import '../../prescriptions/viewmodel/prescriptions_viewmodel.dart';

/// Màn hình Chụp hình Scan chỉ số (Máy đo Huyết áp / Đơn thuốc) chuẩn 40+:
/// Mở Camera hoặc Chọn ảnh từ thư viện -> Nhận diện văn bản/số bằng OCR ->
/// Đổ số liệu (Tâm thu, Tâm trương, Nhịp tim) vào màn hình xác nhận chữ to (30px)
/// để người lớn tuổi kiểm tra và bấm "Lưu vào hệ thống".
class BloodPressureScanScreen extends StatefulWidget {
  final OcrService? ocrService;
  final ElderCareRepository? elderCareRepository;

  const BloodPressureScanScreen({
    super.key,
    this.ocrService,
    this.elderCareRepository,
  });

  @override
  State<BloodPressureScanScreen> createState() =>
      _BloodPressureScanScreenState();
}

class _BloodPressureScanScreenState extends State<BloodPressureScanScreen> {
  late final OcrService _ocrService;
  bool _ownsOcr = false;
  bool _isScanning = false;

  ParsedBloodPressureResult? _scanResult;
  int _sys = 124;
  int _dia = 80;
  int _pulse = 72;

  @override
  void initState() {
    super.initState();
    if (widget.ocrService != null) {
      _ocrService = widget.ocrService!;
    } else if (sl.isRegistered<OcrService>()) {
      _ocrService = sl<OcrService>();
    } else {
      _ocrService = OcrServiceImpl();
      _ownsOcr = true;
    }
  }

  @override
  void dispose() {
    if (_ownsOcr) {
      _ocrService.dispose();
    }
    super.dispose();
  }

  ElderCareRepository? _resolveElderRepo() {
    if (widget.elderCareRepository != null) return widget.elderCareRepository;
    if (sl.isRegistered<ElderCareRepository>()) {
      return sl<ElderCareRepository>();
    }
    if (sl.isRegistered<DatabaseHelper>()) {
      return ElderCareRepositoryImpl(
        localDataSource:
            ElderCareLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
        medicalRecordRepository: sl.isRegistered<MedicalRecordRepository>()
            ? sl<MedicalRecordRepository>()
            : null,
      );
    }
    return null;
  }

  Future<void> _captureAndRecognize(ImageSource source) async {
    setState(() => _isScanning = true);
    try {
      final path = await _ocrService.pickImage(source: source);
      if (path != null && mounted) {
        final parsed = await _ocrService.processBloodPressureImage(path);
        if (mounted) {
          setState(() {
            _scanResult = parsed;
            _sys = parsed.systolic;
            _dia = parsed.diastolic;
            _pulse = parsed.pulse ?? 72;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể đọc ảnh: $e',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _saveConfirmedVitals() async {
    if (_sys <= _dia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chỉ số Tâm thu (số trên) phải lớn hơn Tâm trương (số dưới).',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
      return;
    }

    final repo = _resolveElderRepo();
    if (repo != null) {
      await repo.saveDailyBloodPressure(
        systolic: _sys,
        diastolic: _dia,
        heartRate: _pulse,
        source: 'ocr_scan',
        imagePath: _scanResult?.imagePath,
        note: 'Quét tự động từ ảnh chụp màn hình máy đo huyết áp',
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu chỉ số $_sys/$_dia mmHg (Nhịp tim $_pulse l/p) vào hệ thống!',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: SeniorTokens.callActionGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  void _openPrescriptionScanModal() {
    PrescriptionOcrResultModal.show(
      context,
      ocrService: _ocrService,
      onApplyResult: (rxResult) async {
        final vm = PrescriptionsViewModel();
        await vm.saveOcrPrescription(rxResult);
        vm.dispose();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu toa thuốc (${rxResult.medicines.length} loại) vào lịch uống thuốc!',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: SeniorTokens.callActionGreen,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final eval = DailyVitalLog(
      id: 'preview',
      dateKey: '',
      measuredAt: DateTime.now(),
      systolic: _sys,
      diastolic: _dia,
      heartRate: _pulse,
      statusLevel: DailyVitalLog.evaluateLevel(_sys, _dia),
    );

    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      extendBodyBehindAppBar: true,
      appBar: MedVaultGlassAppBar(
        title: 'Chụp Quét Chỉ Số',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          topPad + 66,
          AppLayoutTokens.screenPadding,
          bottomPad + 36,
        ),
        children: [
          if (_isScanning)
            SeniorCard(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              child: const Column(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Đang đọc con số trên màn hình máy đo...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hệ thống nhận diện chữ số thông minh đang bóc tách Tâm thu, Tâm trương và Nhịp tim.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.iceTextSlate,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else if (_scanResult == null)
            _buildCaptureGuideView()
          else
            _buildConfirmationView(eval),
        ],
      ),
    );
  }

  Widget _buildCaptureGuideView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeniorCard(
          padding: const EdgeInsets.all(22),
          borderColor: AppColors.iceBorderCream,
          child: Column(
            children: [
              // Minh họa trực quan màn hình máy đo huyết áp điện tử
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.iceMetricBox,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.iceCardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 38,
                      color: AppColors.iceOlive,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'SYS 125  •  DIA 80  •  PUL 72',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.iceTextNavy,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Hướng camera thẳng vào màn hình máy đo huyết áp, tránh bóng đèn chói lóa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.iceTextSlate,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SeniorActionButton(
                label: 'Mở Camera chụp máy đo huyết áp',
                icon: Icons.camera_alt_outlined,
                variant: SeniorButtonVariant.primary,
                minHeight: 54,
                onPressed: () => _captureAndRecognize(ImageSource.camera),
              ),
              const SizedBox(height: 10),
              SeniorActionButton(
                label: 'Chọn ảnh máy đo từ Thư viện',
                icon: Icons.photo_library_outlined,
                variant: SeniorButtonVariant.secondaryOutline,
                minHeight: 52,
                onPressed: () => _captureAndRecognize(ImageSource.gallery),
              ),
            ],
          ),
        ),
        const SizedBox(height: SeniorTokens.sectionGap),

        // Lối tắt quét Toa thuốc bác sĩ ngay trên cùng màn hình Scan
        SeniorSectionBlock(
          title: 'Bạn muốn chụp Đơn thuốc bác sĩ?',
          subtitle: 'Tự động đọc tên thuốc, hàm lượng và lên lịch nhắc uống',
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.accent,
          bottomSpacing: 0,
          child: SeniorCard(
            padding: const EdgeInsets.all(20),
            child: SeniorActionButton(
              label: 'Chụp / Quét ảnh Đơn thuốc bác sĩ',
              icon: Icons.medication_rounded,
              variant: SeniorButtonVariant.amberHighlight,
              minHeight: 56,
              onPressed: _openPrescriptionScanModal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationView(DailyVitalLog eval) {
    final autoDetected = _scanResult!.isAutoDetected;
    final imgPath = _scanResult!.imagePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trạng thái đọc số từ ảnh
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: autoDetected
                ? SeniorTokens.callActionGreenSoft
                : SeniorTokens.warningAmberBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: autoDetected
                  ? SeniorTokens.callActionGreen
                  : SeniorTokens.warningAmberBorder,
              width: 1.6,
            ),
          ),
          child: Row(
            children: [
              Icon(
                autoDetected
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                size: 30,
                color: autoDetected
                    ? SeniorTokens.callActionGreen
                    : SeniorTokens.warningAmberText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  autoDetected
                      ? 'Đã nhận diện thành công con số trên máy đo! Mời bác kiểm tra lại trước khi lưu.'
                      : 'Ảnh màn hình hơi mờ/nghiêng nên chưa rõ đủ 3 số. Mời bác bấm nút (-) (+) bên dưới để chỉnh lại cho đúng.',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (imgPath != null &&
            imgPath.isNotEmpty &&
            File(imgPath).existsSync()) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: Image.file(File(imgPath), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Màn hình xác nhận 3 chỉ số chữ cực to (30px)
        SeniorCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kiểm tra chỉ số bóc tách:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.iceTextNavy,
                ),
              ),
              const SizedBox(height: 14),
              SeniorNumberStepperField(
                label: 'Tâm thu (Số trên - SYS)',
                unit: 'mmHg',
                value: _sys,
                min: 70,
                max: 250,
                accentColor: AppColors.iceTextNavy,
                onChanged: (v) => setState(() => _sys = v),
              ),
              const SizedBox(height: 12),
              SeniorNumberStepperField(
                label: 'Tâm trương (Số dưới - DIA)',
                unit: 'mmHg',
                value: _dia,
                min: 40,
                max: 150,
                accentColor: AppColors.iceOliveDark,
                onChanged: (v) => setState(() => _dia = v),
              ),
              const SizedBox(height: 12),
              SeniorNumberStepperField(
                label: 'Nhịp tim (Mạch - PULSE)',
                unit: 'nhịp/phút',
                value: _pulse,
                min: 35,
                max: 190,
                accentColor: AppColors.textWarmBrown,
                onChanged: (v) => setState(() => _pulse = v),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Kết luận: ${eval.statusLabelVi} — ${eval.seniorAdviceVi}',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nút lớn "Lưu vào hệ thống"
              SeniorActionButton(
                label: 'Lưu vào hệ thống',
                icon: Icons.save_rounded,
                variant: SeniorButtonVariant.callNow,
                minHeight: 58,
                onPressed: _saveConfirmedVitals,
              ),
              const SizedBox(height: 12),
              SeniorActionButton(
                label: 'Chụp lại ảnh khác',
                icon: Icons.refresh_rounded,
                variant: SeniorButtonVariant.secondaryOutline,
                minHeight: 54,
                onPressed: () => setState(() => _scanResult = null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
