import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/nutrition_item.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../viewmodel/nutrition_viewmodel.dart';

/// Trang Dinh dưỡng & Thực phẩm chức năng chuẩn 40+:
/// Chia 2 Tab lớn rõ ràng:
/// (a) Chế độ ăn uống & Dinh dưỡng (Nên ăn / Nên kiêng)
/// (b) Thực phẩm chức năng đang dùng / tham khảo (Hình ảnh sản phẩm, công dụng, liều dùng)
class NutritionSupplementsScreen extends StatefulWidget {
  final NutritionViewModel? viewModel;
  final int initialTabIndex;

  const NutritionSupplementsScreen({
    super.key,
    this.viewModel,
    this.initialTabIndex = 0,
  });

  @override
  State<NutritionSupplementsScreen> createState() =>
      _NutritionSupplementsScreenState();
}

class _NutritionSupplementsScreenState
    extends State<NutritionSupplementsScreen> {
  late final NutritionViewModel _viewModel;
  bool _ownsVm = false;
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex.clamp(0, 1);
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = NutritionViewModel();
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

  Future<void> _openAddNutritionDialog() async {
    bool isShouldEat = true;
    final foodCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '2–3 bữa / tuần');
    final reasonCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Thêm Ghi Chú Ăn Uống',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        selected: isShouldEat,
                        selectedColor: SeniorTokens.callActionGreen,
                        onSelected: (_) => setModal(() => isShouldEat = true),
                        label: Text(
                          'Nên ăn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isShouldEat
                                ? Colors.white
                                : AppColors.iceTextNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        selected: !isShouldEat,
                        selectedColor: SeniorTokens.highBpRedText,
                        onSelected: (_) => setModal(() => isShouldEat = false),
                        label: Text(
                          'Nên kiêng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: !isShouldEat
                                ? Colors.white
                                : AppColors.iceTextNavy,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: foodCtrl,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: 'Tên thực phẩm / món ăn *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: 'Khẩu phần / Mức độ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    labelText: 'Công dụng hoặc lý do kiêng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(fontSize: 17)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(110, 50),
              ),
              onPressed: () {
                if (foodCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _viewModel.addCustomNutritionNote(
                  isShouldEat: isShouldEat,
                  foodName: foodCtrl.text,
                  amount: amountCtrl.text,
                  reason: reasonCtrl.text.trim().isEmpty
                      ? 'Theo dặn dò chế độ dinh dưỡng của bác sĩ.'
                      : reasonCtrl.text,
                );
              },
              child: const Text(
                'Lưu lại',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSupplementSheet([DietarySupplement? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.productName ?? '');
    final catCtrl =
        TextEditingController(text: existing?.category ?? 'Bổ xương khớp');
    final benefitCtrl = TextEditingController(text: existing?.benefits ?? '');
    final doseCtrl = TextEditingController(text: existing?.dosageGuide ?? '');
    final cautionCtrl =
        TextEditingController(text: existing?.cautionNote ?? '');
    String? imgPath = existing?.imagePath;
    SupplementUsageStatus status =
        existing?.usageStatus ?? SupplementUsageStatus.usingNow;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
          final bottomPad = MediaQuery.paddingOf(ctx).bottom;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding:
                EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset + bottomPad),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.medication_liquid_rounded,
                        size: 30,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          existing != null
                              ? 'Sửa Thực Phẩm Chức Năng'
                              : 'Thêm Thực Phẩm Chức Năng',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SeniorLabeledIconButton(
                        icon: Icons.close_rounded,
                        label: 'Đóng',
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SeniorActionButton(
                    label: imgPath != null
                        ? 'Đổi ảnh hộp sản phẩm'
                        : 'Chụp / Chọn ảnh hộp sản phẩm',
                    icon: Icons.add_a_photo_rounded,
                    variant: SeniorButtonVariant.secondaryOutline,
                    onPressed: () async {
                      final ocr = sl.isRegistered<OcrService>()
                          ? sl<OcrService>()
                          : OcrServiceImpl();
                      final picked =
                          await ocr.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setModal(() => imgPath = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected: status == SupplementUsageStatus.usingNow,
                          selectedColor: SeniorTokens.callActionGreen,
                          onSelected: (_) => setModal(
                            () => status = SupplementUsageStatus.usingNow,
                          ),
                          label: Text(
                            'Đang dùng hằng ngày',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: status == SupplementUsageStatus.usingNow
                                  ? Colors.white
                                  : AppColors.iceTextNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          selected: status == SupplementUsageStatus.reference,
                          selectedColor: const Color(0xFF2B6CB0),
                          onSelected: (_) => setModal(
                            () => status = SupplementUsageStatus.reference,
                          ),
                          label: Text(
                            'Lưu tham khảo',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: status == SupplementUsageStatus.reference
                                  ? Colors.white
                                  : AppColors.iceTextNavy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catCtrl,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      labelText: 'Nhóm hỗ trợ (VD: Bổ khớp, Tim mạch)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: benefitCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      labelText: 'Công dụng chính *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: doseCtrl,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      labelText: 'Liều dùng & Thời điểm uống *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cautionCtrl,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      labelText: 'Lưu ý khi dùng chung thuốc tây',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SeniorActionButton(
                    label: 'Lưu sản phẩm',
                    icon: Icons.check_circle_rounded,
                    variant: SeniorButtonVariant.callNow,
                    minHeight: 56,
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      _viewModel.addOrUpdateSupplement(
                        existingId: existing?.id,
                        productName: nameCtrl.text,
                        category: catCtrl.text,
                        benefits: benefitCtrl.text.trim().isEmpty
                            ? 'Bổ sung dưỡng chất hỗ trợ sức khỏe.'
                            : benefitCtrl.text,
                        dosageGuide: doseCtrl.text.trim().isEmpty
                            ? 'Uống theo hướng dẫn trên nhãn hộp.'
                            : doseCtrl.text,
                        status: status,
                        cautionNote: cautionCtrl.text,
                        imagePath: imgPath,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBodyBehindAppBar: true,
          appBar: MedVaultGlassAppBar(
            title: 'Dinh Dưỡng & Thuốc Bổ',
            onBack: () => Navigator.pop(context),
          ),
          body: Column(
            children: [
              SizedBox(height: topPad + 62),
              // Segmented Control 2 Tab cân đối
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppLayoutTokens.screenPadding,
                  4,
                  AppLayoutTokens.screenPadding,
                  10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.timelineInputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iceCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BigTabButton(
                          icon: Icons.restaurant_menu_rounded,
                          label: 'Chế độ Ăn uống',
                          isSelected: _activeTab == 0,
                          onTap: () => setState(() => _activeTab = 0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _BigTabButton(
                          icon: Icons.medication_outlined,
                          label: 'Thực phẩm chức năng',
                          isSelected: _activeTab == 1,
                          onTap: () => setState(() => _activeTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: _activeTab == 0
                    ? _buildNutritionTab(bottomPad)
                    : _buildSupplementsTab(bottomPad),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab(double bottomPad) {
    final eatItems = _viewModel.shouldEatList;
    final avoidItems = _viewModel.shouldAvoidList;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppLayoutTokens.screenPadding,
        8,
        AppLayoutTokens.screenPadding,
        bottomPad + 36,
      ),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: NutritionViewModel.healthTags.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final tag = NutritionViewModel.healthTags[idx];
              final selected = tag == _viewModel.selectedHealthTag;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color:
                      selected ? AppColors.primary : AppColors.iceCardBorder,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                onSelected: (_) => _viewModel.selectHealthTag(tag),
                label: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.iceTextNavy,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        SeniorActionButton(
          label: 'Thêm món ăn bác sĩ dặn dò',
          icon: Icons.add_circle_rounded,
          variant: SeniorButtonVariant.secondaryOutline,
          onPressed: _openAddNutritionDialog,
        ),
        const SizedBox(height: SeniorTokens.sectionGap),

        // KHỐI 1: THỰC PHẨM NÊN ĂN
        SeniorSectionBlock(
          title: 'Thực phẩm NÊN ĂN',
          subtitle: 'Ưu tiên bổ sung đều đặn trong thực đơn hằng tuần',
          icon: Icons.check_circle_rounded,
          iconColor: SeniorTokens.callActionGreen,
          iconBgColor: SeniorTokens.callActionGreenSoft,
          child: Column(
            children: eatItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _NutritionRuleCard(
                      item: item,
                      isPositive: true,
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // KHỐI 2: THỰC PHẨM NÊN KIÊNG
        SeniorSectionBlock(
          title: 'Thực phẩm NÊN KIÊNG / HẠN CHẾ',
          subtitle: 'Giúp tránh tăng huyết áp, đau khớp & rối loạn mỡ máu',
          icon: Icons.do_not_disturb_on_rounded,
          iconColor: SeniorTokens.highBpRedText,
          iconBgColor: SeniorTokens.highBpRedBg,
          bottomSpacing: 0,
          child: Column(
            children: avoidItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _NutritionRuleCard(
                      item: item,
                      isPositive: false,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementsTab(double bottomPad) {
    final list = _viewModel.supplements;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppLayoutTokens.screenPadding,
        8,
        AppLayoutTokens.screenPadding,
        bottomPad + 36,
      ),
      children: [
        SeniorActionButton(
          label: 'Thêm thực phẩm chức năng mới',
          icon: Icons.add_box_rounded,
          variant: SeniorButtonVariant.primary,
          minHeight: 56,
          onPressed: () => _openAddSupplementSheet(),
        ),
        const SizedBox(height: SeniorTokens.sectionGap),

        for (int i = 0; i < list.length; i++) ...[
          _SupplementBigCard(
            item: list[i],
            onToggleStatus: () => _viewModel.toggleSupplementStatus(list[i]),
            onEdit: () => _openAddSupplementSheet(list[i]),
            onDelete: () => _viewModel.deleteSupplement(list[i]),
          ),
          if (i < list.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _BigTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BigTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.iceTextNavy.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.iceTextMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.iceTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionRuleCard extends StatelessWidget {
  final NutritionGuideline item;
  final bool isPositive;

  const _NutritionRuleCard({
    required this.item,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        isPositive ? AppColors.reportTeal : AppColors.iceCriticalBadge;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.iceCardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isPositive ? 'NÊN ĂN' : 'NÊN KIÊNG',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.55,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: AppColors.dotMuted)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.healthTag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.iceTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.foodName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.iceTextNavy,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Khuyến nghị: ${item.recommendedAmount}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.benefitOrRisk,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.iceTextSlate,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplementBigCard extends StatelessWidget {
  final DietarySupplement item;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplementBigCard({
    required this.item,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildProductImage() {
    ImageProvider? img;
    final path = item.imagePath;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('assets/')) {
        img = AssetImage(path);
      } else if (!path.startsWith('http') && File(path).existsSync()) {
        img = FileImage(File(path));
      }
    }
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceCardBorder, width: 1.3),
        image:
            img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
      ),
      child: img == null
          ? const Icon(
              Icons.medication_liquid_rounded,
              size: 40,
              color: AppColors.primary,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usingNow = item.isUsingNow;
    final statusColor =
        usingNow ? AppColors.reportTeal : AppColors.textWarmBrown;

    return SeniorCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usingNow ? 'ĐANG SỬ DỤNG' : 'ĐANG THAM KHẢO',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.iceTextNavy,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.iceTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.benefits,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w400,
              color: AppColors.iceTextSlate,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.iceMetricBox,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Liều dùng: ${item.dosageGuide}',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.iceTextNavy,
                height: 1.38,
              ),
            ),
          ),
          if (item.cautionNote != null &&
              item.cautionNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.iceAllergyBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lưu ý: ${item.cautionNote!}',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.iceCriticalBadge,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SeniorActionButton(
            label: usingNow
                ? 'Chuyển sang nhóm Tham khảo'
                : 'Đánh dấu Đang sử dụng',
            icon: Icons.swap_horiz_rounded,
            variant: SeniorButtonVariant.secondaryOutline,
            onPressed: onToggleStatus,
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
