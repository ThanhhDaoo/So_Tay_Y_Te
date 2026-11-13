import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../viewmodel/documents_state.dart';
import '../viewmodel/documents_viewmodel.dart';
import 'widgets/ai_ocr_scanner_card.dart';
import 'widgets/ai_ocr_scanner_modal.dart';
import 'widgets/document_blood_test_card.dart';
import 'widgets/document_endoscopy_card.dart';
import 'widgets/document_filter_chips.dart';
import 'widgets/document_prescription_ocr_card.dart';
import 'widgets/document_viewer_modal.dart';
import 'widgets/document_viewer_tip_badge.dart';
import 'widgets/document_xray_card.dart';
import 'widgets/documents_header.dart';
import 'widgets/security_storage_banner.dart';
import 'widgets/share_doctor_qr_modal.dart';
import 'widgets/share_doctor_quick_action.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    this.showBottomNav = true,
  });

  final bool showBottomNav;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final DocumentsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DocumentsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.iceOlive,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onSelectBottomTab(int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MainShellScreen(initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      extendBody: true,
      bottomNavigationBar: widget.showBottomNav
          ? IceBottomNavBar(
              selectedIndex: 4,
              onSelectTab: _onSelectBottomTab,
            )
          : null,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;

          final showBlood = state.selectedCategory == DocumentCategory.all ||
              state.selectedCategory == DocumentCategory.bloodTests;
          final showEndo = state.selectedCategory == DocumentCategory.all ||
              state.selectedCategory == DocumentCategory.endoscopy;
          final showRx = state.selectedCategory == DocumentCategory.all ||
              state.selectedCategory == DocumentCategory.prescriptions;
          final showXray = state.selectedCategory == DocumentCategory.all ||
              state.selectedCategory == DocumentCategory.xray;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DocumentsHeader(
                  onProfileTap: () => _showSnack('Kho tài liệu của Thu Trang'),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  110 + bottomPadding,
                ),
                sliver: SliverList.list(
                  children: [
                    SecurityStorageBanner(
                      usedStorageMb: state.usedStorageMb,
                      savedStorageMb: state.savedStorageMb,
                      totalStorageGb: state.totalStorageGb,
                      docCount: state.totalDocCount,
                    ),
                    const SizedBox(height: 16),
                    AiOcrScannerCard(
                      onScanCamera: () => AiOcrScannerModal.show(
                        context,
                        onScanComplete: () => _showSnack('Đã thêm 1 đơn thuốc mới quét vào kho!'),
                      ),
                      onSelectFromAlbum: () => AiOcrScannerModal.show(
                        context,
                        onScanComplete: () => _showSnack('Đã phân tích và lưu tài liệu từ album!'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DocumentFilterChips(
                      selectedCategory: state.selectedCategory,
                      onSelectCategory: _viewModel.selectCategory,
                      onFilterTap: () =>
                          _showSnack('Tùy chọn bộ lọc nâng cao'),
                    ),
                    if (state.showViewerTip) ...[
                      const SizedBox(height: 12),
                      DocumentViewerTipBadge(
                        onDismiss: _viewModel.dismissViewerTip,
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tài Liệu Gần Đây',
                          style: AppTypography.heading3.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                          ),
                        ),
                        Text(
                          'Sắp xếp: Mới nhất',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.44,
                            color: const Color(0xFF3D4947),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (showBlood) ...[
                      DocumentBloodTestCard(
                        onTapDetail: () => DocumentViewerModal.show(
                          context,
                          title: 'Xét Nghiệm Huyết Học Tổng Quát (CBC)',
                          category: 'Huyết học & Sinh hóa',
                          date: '18/04/2024',
                          hospital: 'BV Đa Khoa Quốc Tế Vinmec',
                          imageAsset: 'assets/images/img_doc_blood_test.png',
                          keyFindings: [
                            {'label': 'Bạch cầu (WBC)', 'value': '7.2 K/uL', 'status': 'Bình thường'},
                            {'label': 'Hồng cầu (RBC)', 'value': '4.65 M/uL', 'status': 'Bình thường'},
                            {'label': 'Huyết sắc tố (Hb)', 'value': '138 g/L', 'status': 'Bình thường'},
                            {'label': 'Tiểu cầu (PLT)', 'value': '248 K/uL', 'status': 'Bình thường'},
                            {'label': 'Đường huyết đói (Glucose)', 'value': '5.2 mmol/L', 'status': 'Bình thường'},
                          ],
                        ),
                        onMoreTap: () => _showSnack('Tùy chọn: Tải về • Đổi tên • Xóa'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showEndo) ...[
                      DocumentEndoscopyCard(
                        onTapDetail: () => DocumentViewerModal.show(
                          context,
                          title: 'Kết Quả Nội Soi Dạ Dày HP (+)',
                          category: 'Thăm dò chức năng',
                          date: '18/04/2024',
                          hospital: 'Khoa Tiêu hóa - Gan mật Vinmec',
                          imageAsset: 'assets/images/img_doc_endoscopy.png',
                          keyFindings: [
                            {'label': 'Thực quản', 'value': 'Bình thường, không viêm', 'status': 'Bình thường'},
                            {'label': 'Hang vị dạ dày', 'value': 'Phù nề, trợt nông 2-3mm', 'status': 'Viêm nhẹ'},
                            {'label': 'Helicobacter Pylori', 'value': 'CLO-Test Dương tính (++)', 'status': 'Cảnh báo (+)'},
                            {'label': 'Hành tá tràng', 'value': 'Niêm mạc nhẵn, co bóp tốt', 'status': 'Bình thường'},
                          ],
                        ),
                        onMoreTap: () => _showSnack('Tùy chọn: Tải về • Đổi tên • Xóa'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showRx) ...[
                      DocumentPrescriptionOcrCard(
                        onViewScannedRx: () => DocumentViewerModal.show(
                          context,
                          title: 'Đơn Thuốc Ngoại Trú Đã Quét OCR',
                          category: 'Toa thuốc điện tử',
                          date: '18/04/2024',
                          hospital: 'Khoa Tiêu Hóa - Vinmec',
                          imageAsset: 'assets/images/img_doc_blood_test.png',
                          keyFindings: [
                            {'label': 'Nexium 40mg', 'value': '14 viên (1v/ngày)', 'status': 'Đang dùng'},
                            {'label': 'Amoxicillin 500mg', 'value': '56 viên (4v/ngày)', 'status': 'Đang dùng'},
                            {'label': 'Clarithromycin 500mg', 'value': '28 viên (2v/ngày)', 'status': 'Đang dùng'},
                          ],
                        ),
                        onDrugTap: (drug) => DocumentViewerModal.show(
                          context,
                          title: 'Chi Tiết Thuốc: $drug',
                          category: 'Dược thư y tế',
                          date: '18/04/2024',
                          hospital: 'Dược thư Quốc Gia Việt Nam',
                          imageAsset: 'assets/images/img_doc_blood_test.png',
                          keyFindings: [
                            {'label': 'Tên hoạt chất', 'value': drug, 'status': 'Kê đơn'},
                            {'label': 'Chỉ định điều trị', 'value': 'Diệt khuẩn HP & Loét dạ dày', 'status': 'Đạt chuẩn'},
                            {'label': 'Cảnh báo dị ứng', 'value': 'Không có chống chỉ định với BN', 'status': 'Bình thường'},
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showXray) ...[
                      DocumentXrayCard(
                        onTapDetail: () => DocumentViewerModal.show(
                          context,
                          title: 'Phim X-Quang Ngực Thẳng Kỹ Thuật Số',
                          category: 'Chẩn đoán hình ảnh',
                          date: '10/01/2024',
                          hospital: 'Khoa Chẩn Đoán Hình Ảnh',
                          imageAsset: 'assets/images/img_doc_xray.png',
                          keyFindings: [
                            {'label': 'Trường phổi 2 bên', 'value': 'Sáng đều, không ứ khí', 'status': 'Bình thường'},
                            {'label': 'Bóng tim', 'value': 'Kích thước bình thường, ICT < 0.5', 'status': 'Bình thường'},
                            {'label': 'Góc sườn hoành', 'value': 'Hai bên sáng nhọn, không dịch', 'status': 'Bình thường'},
                            {'label': 'Khung xương lồng ngực', 'value': 'Không gãy vỡ, không tổn thương', 'status': 'Bình thường'},
                          ],
                        ),
                        onMoreTap: () => _showSnack('Tùy chọn: Tải về • Đổi tên • Xóa'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ShareDoctorQuickAction(
                      onCreateQr: () => ShareDoctorQrModal.show(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

