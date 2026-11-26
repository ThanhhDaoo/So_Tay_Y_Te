import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common_widgets/layout/app_layout.dart';
import '../../emergency_card/view/widgets/ice_bottom_nav_bar.dart';
import '../../main_shell/view/main_shell_screen.dart';
import '../viewmodel/documents_state.dart';
import '../viewmodel/documents_viewmodel.dart';
import 'widgets/ai_ocr_scanner_card.dart';
import 'widgets/ai_ocr_scanner_modal.dart';
import 'widgets/document_filter_chips.dart';
import 'widgets/document_viewer_modal.dart';
import 'widgets/document_viewer_tip_badge.dart';
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

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DocumentsHeader(
                  onProfileTap: () => _showSnack('Kho tài liệu y tế cá nhân'),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppLayoutTokens.screenPadding,
                  16,
                  AppLayoutTokens.screenPadding,
                  110 + bottomPadding,
                ),
                sliver: SliverList.list(
                  children: [
                    // Cụm 1: Trạng thái E2EE mảnh gọn + Công cụ Quét AI
                    SecurityStorageBanner(
                      usedStorageMb: state.usedStorageMb,
                      savedStorageMb: state.savedStorageMb,
                      totalStorageGb: state.totalStorageGb,
                      docCount: state.totalDocCount,
                    ),
                    const SizedBox(height: AppLayoutTokens.cardGap),
                    AiOcrScannerCard(
                      onScanCamera: () => AiOcrScannerModal.show(
                        context,
                        documentsViewModel: _viewModel,
                        onScanComplete: () {
                          _viewModel.loadDocuments();
                          _showSnack('Đã thêm 1 đơn thuốc mới quét vào kho!');
                        },
                      ),
                      onSelectFromAlbum: () => AiOcrScannerModal.show(
                        context,
                        documentsViewModel: _viewModel,
                        onScanComplete: () {
                          _viewModel.loadDocuments();
                          _showSnack(
                            'Đã phân tích và lưu tài liệu từ album!',
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppLayoutTokens.sectionGap),

                    // Cụm 2: Phân loại & Danh sách Tài liệu gần đây
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
                    const SizedBox(height: AppLayoutTokens.sectionGap),

                    SectionContainer(
                      title: 'Tài Liệu Gần Đây',
                      bottomSpacing: AppLayoutTokens.sectionGap,
                      trailing: const Text(
                        'Mới nhất',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D4947),
                        ),
                      ),
                      child: _buildDocumentsList(state),
                    ),

                    // Cụm 3: Chia sẻ QR an toàn cho Bác sĩ
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

  Widget _buildDocumentsList(DocumentsState state) {
    if (state.totalDocCount == 0) {
      return CleanCard(
        borderColor: const Color(0xFFE5DFD4),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.surfaceWarm,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.folder_open_outlined,
                  size: 28,
                  color: AppColors.iceOlive,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa Có Tài Liệu Nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sử dụng chức năng chụp quét ở trên hoặc đính kèm ảnh khi thêm đợt khám mới.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.iceTextSlate,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final filteredDocs = state.documents
        .where(
          (d) =>
              state.selectedCategory == DocumentCategory.all ||
              d.category == state.selectedCategory,
        )
        .toList();

    if (filteredDocs.isEmpty) {
      return CleanCard(
        borderColor: const Color(0xFFE5DFD4),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            const Icon(
              Icons.filter_alt_off_outlined,
              size: 32,
              color: AppColors.iceOlive,
            ),
            const SizedBox(height: 10),
            Text(
              'Chưa có tài liệu thuộc danh mục "${state.selectedCategory.label}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextNavy,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _viewModel.selectCategory(DocumentCategory.all),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Xem tất cả tài liệu'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.iceOlive,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < filteredDocs.length; i++) ...[
          _DynamicDocumentCard(
            doc: filteredDocs[i],
            onTap: () => DocumentViewerModal.show(
              context,
              title: filteredDocs[i].title,
              category: filteredDocs[i].category.label,
              date: filteredDocs[i].date,
              hospital: filteredDocs[i].hospital,
              imageAsset: filteredDocs[i].imagePath,
              keyFindings: filteredDocs[i].keyFindings,
            ),
            onDelete: () async {
              final doc = filteredDocs[i];
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Xác nhận xóa tài liệu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    'Bạn có chắc chắn muốn xóa tài liệu "${doc.title}" khỏi kho lưu trữ không?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _viewModel.deleteDocument(doc.id);
                if (mounted) {
                  _showSnack('Đã xóa tài liệu: ${doc.title}');
                }
              }
            },
          ),
          if (i < filteredDocs.length - 1)
            const SizedBox(height: AppLayoutTokens.cardGap),
        ],
      ],
    );
  }
}

/// Thẻ tài liệu y tế chuẩn 3-Point Rule:
/// (1) Danh mục & Ngày, (2) Tên tài liệu đậm rõ, (3) Cơ sở y tế 1 dòng.
class _DynamicDocumentCard extends StatelessWidget {
  final MedicalDocumentItem doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DynamicDocumentCard({
    required this.doc,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalFile = !doc.imagePath.startsWith('assets/');
    return CleanCard(
      onTap: onTap,
      borderColor: const Color(0xFFE5DFD4),
      padding: const EdgeInsets.all(AppLayoutTokens.cardPadding),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.surfaceWarm,
              child: isLocalFile && File(doc.imagePath).existsSync()
                  ? Image.file(File(doc.imagePath), fit: BoxFit.cover)
                  : Image.asset(
                      doc.imagePath.startsWith('assets/')
                          ? doc.imagePath
                          : 'assets/images/img_doc_blood_test.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.iceOlive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.category.label,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceOlive,
                        ),
                      ),
                    ),
                    Text(
                      doc.date,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.iceTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doc.hospital,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.black38,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
