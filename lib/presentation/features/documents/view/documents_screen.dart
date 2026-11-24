import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
                          _showSnack('Đã phân tích và lưu tài liệu từ album!');
                        },
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
                        Flexible(
                          child: Text(
                            'Tài Liệu Gần Đây',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.heading3.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iceTextNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Sắp xếp: Mới nhất',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.44,
                              color: const Color(0xFF3D4947),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.totalDocCount == 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5DFD4)),
                        ),
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
                              'Hồ sơ của bạn chưa có tài liệu bệnh án, kết quả xét nghiệm hay toa thuốc nào. Hãy sử dụng chức năng chụp quét ở trên hoặc đính kèm ảnh khi thêm đợt khám mới.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.iceTextSlate,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Builder(
                        builder: (context) {
                          final filteredDocs = state.documents
                              .where((d) =>
                                  state.selectedCategory == DocumentCategory.all ||
                                  d.category == state.selectedCategory)
                              .toList();
                          if (filteredDocs.isEmpty) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5DFD4)),
                              ),
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
                                    onPressed: () =>
                                        _viewModel.selectCategory(DocumentCategory.all),
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
                              for (final doc in filteredDocs) ...[
                                _DynamicDocumentCard(
                                  doc: doc,
                                  onTap: () => DocumentViewerModal.show(
                                    context,
                                    title: doc.title,
                                    category: doc.category.label,
                                    date: doc.date,
                                    hospital: doc.hospital,
                                    imageAsset: doc.imagePath,
                                    keyFindings: doc.keyFindings,
                                  ),
                                  onDelete: () async {
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
                                      if (context.mounted) {
                                        _showSnack('Đã xóa tài liệu: ${doc.title}');
                                      }
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          );
                        },
                      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DFD4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.iceOlive.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doc.category.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.iceOlive,
                              ),
                            ),
                          ),
                          Text(
                            doc.date,
                            style: const TextStyle(fontSize: 11, color: AppColors.iceTextSlate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
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
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black38),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

