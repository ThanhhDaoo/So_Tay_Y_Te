import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/health_video.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../viewmodel/health_videos_viewmodel.dart';
import 'video_player_detail_screen.dart';

/// Trang Video sức khỏe chuẩn 40+:
/// Hiển thị Thumbnail lớn, Tiêu đề to, Thời lượng, Phân loại bài tập.
/// Bấm vào mở Trình phát video trực quan.
class HealthVideosScreen extends StatefulWidget {
  final HealthVideosViewModel? viewModel;

  const HealthVideosScreen({super.key, this.viewModel});

  @override
  State<HealthVideosScreen> createState() => _HealthVideosScreenState();
}

class _HealthVideosScreenState extends State<HealthVideosScreen> {
  late final HealthVideosViewModel _viewModel;
  bool _ownsVm = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = HealthVideosViewModel();
      _ownsVm = true;
    }
  }

  @override
  void dispose() {
    if (_ownsVm) _viewModel.dispose();
    super.dispose();
  }

  void _openVideoPlayer(HealthVideo video) {
    _viewModel.recordWatched(video);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerDetailScreen(
          video: video,
          onToggleSave: () => _viewModel.toggleSave(video),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final videos = _viewModel.videos;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 146,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
              child: SeniorLabeledIconButton(
                icon: Icons.arrow_back_rounded,
                label: 'Quay lại',
                onTap: () => Navigator.pop(context),
              ),
            ),
            title: const Text(
              'Video Sức Khỏe',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.iceTextNavy,
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              AppLayoutTokens.screenPadding,
              12,
              AppLayoutTokens.screenPadding,
              bottomPad + 36,
            ),
            children: [
              const Text(
                'Chọn nhóm bài tập phù hợp:',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.iceTextNavy,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: HealthVideosViewModel.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = HealthVideosViewModel.categories[idx];
                    final selected = cat == _viewModel.selectedCategory;
                    return ChoiceChip(
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      onSelected: (_) => _viewModel.selectCategory(cat),
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              selected ? Colors.white : AppColors.iceTextNavy,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: SeniorTokens.sectionGap),

              if (_viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (int i = 0; i < videos.length; i++) ...[
                  _HealthVideoBigCard(
                    video: videos[i],
                    onPlay: () => _openVideoPlayer(videos[i]),
                    onToggleSave: () => _viewModel.toggleSave(videos[i]),
                  ),
                  if (i < videos.length - 1) const SizedBox(height: 22),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _HealthVideoBigCard extends StatelessWidget {
  final HealthVideo video;
  final VoidCallback onPlay;
  final VoidCallback onToggleSave;

  const _HealthVideoBigCard({
    required this.video,
    required this.onPlay,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return SeniorCard(
      onTap: onPlay,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail lớn 196px kèm nút Play trực quan ở giữa & nhãn Thời lượng
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 196,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (video.thumbnailUrl.startsWith('assets/'))
                    Image.asset(video.thumbnailUrl, fit: BoxFit.cover)
                  else
                    Container(color: const Color(0xFF2D3B32)),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x99000000),
                        ],
                      ),
                    ),
                  ),
                  // Nhãn Phân loại bài tập góc trái trên
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        video.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // Nhãn Thời lượng góc phải dưới
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            video.durationLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nút Play lớn chính giữa luôn kèm chữ tiếng Việt
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: SeniorTokens.callActionGreen.withValues(
                          alpha: 0.94,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Bấm phát video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tiêu đề to rõ
          Text(
            video.title,
            style: const TextStyle(
              fontSize: 19.5,
              fontWeight: FontWeight.w800,
              color: AppColors.iceTextNavy,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person_pin_rounded,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  video.instructorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iceTextSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            video.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.iceTextSlate,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SeniorActionButton(
                  label: 'Mở bài tập này',
                  icon: Icons.play_arrow_rounded,
                  variant: SeniorButtonVariant.callNow,
                  onPressed: onPlay,
                ),
              ),
              const SizedBox(width: 10),
              SeniorLabeledIconButton(
                icon: video.isSaved
                    ? Icons.bookmark_added_rounded
                    : Icons.bookmark_border_rounded,
                label: video.isSaved ? 'Đã lưu' : 'Lưu lại',
                onTap: onToggleSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
