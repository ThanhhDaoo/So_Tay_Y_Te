import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../viewmodel/documents_state.dart';
import '../viewmodel/documents_viewmodel.dart';
import 'widgets/ai_ocr_scanner_card.dart';
import 'widgets/document_blood_test_card.dart';
import 'widgets/document_endoscopy_card.dart';
import 'widgets/document_filter_chips.dart';
import 'widgets/document_prescription_ocr_card.dart';
import 'widgets/document_viewer_tip_badge.dart';
import 'widgets/document_xray_card.dart';
import 'widgets/documents_header.dart';
import 'widgets/security_storage_banner.dart';
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
    if (index == 4) return;
    if (index <= 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainShellScreen(initialIndex: index),
        ),
      );
      return;
    }
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
                      onScanCamera: () =>
                          _showSnack('Mở máy ảnh quét toa thuốc...'),
                      onSelectFromAlbum: () =>
                          _showSnack('Mở thư viện ảnh thiết bị...'),
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
                        onTapDetail: () => _showSnack(
                          'Xem chi tiết Phiếu xét nghiệm sinh hóa máu',
                        ),
                        onMoreTap: () => _showSnack('Tùy chọn tài liệu'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showEndo) ...[
                      DocumentEndoscopyCard(
                        onTapDetail: () => _showSnack(
                          'Xem chi tiết Kết quả Nội soi thực quản dạ dày',
                        ),
                        onMoreTap: () => _showSnack('Tùy chọn tài liệu'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showRx) ...[
                      DocumentPrescriptionOcrCard(
                        onViewScannedRx: () => _showSnack(
                          'Mở ảnh đơn thuốc quét gốc (WebP • 210 KB)',
                        ),
                        onDrugTap: (drug) =>
                            _showSnack('Chi tiết thuốc: $drug'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showXray) ...[
                      DocumentXrayCard(
                        onTapDetail: () => _showSnack(
                          'Xem chi tiết Phim chụp X-Quang lồng ngực thẳng',
                        ),
                        onMoreTap: () => _showSnack('Tùy chọn tài liệu'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ShareDoctorQuickAction(
                      onCreateQr: () => _showSnack(
                        'Đang tạo mã QR chia sẻ an toàn với mật khẩu 24h...',
                      ),
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

