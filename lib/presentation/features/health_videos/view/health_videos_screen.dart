import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/health_video.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';
import '../viewmodel/health_videos_viewmodel.dart';
import 'video_player_detail_screen.dart';

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
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final videos = _viewModel.videos;

        return Scaffold(
          backgroundColor: AppColors.iceBackground,
          extendBodyBehindAppBar: true,
          appBar: MedVaultGlassAppBar(
            title: 'Video Sức Khỏe',
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
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: HealthVideosViewModel.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = HealthVideosViewModel.categories[idx];
                    final selected = cat == _viewModel.selectedCategory;
                    return ChoiceChip(
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.iceCardBorder,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      onSelected: (_) => _viewModel.selectCategory(cat),
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : AppColors.iceTextNavy,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              if (_viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.iceOlive),
                  ),
                )
              else
                for (int i = 0; i < videos.length; i++) ...[
                  _HealthVideoEditorialCard(
                    video: videos[i],
                    onPlay: () => _openVideoPlayer(videos[i]),
                    onToggleSave: () => _viewModel.toggleSave(videos[i]),
                  ),
                  if (i < videos.length - 1) const SizedBox(height: 18),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _HealthVideoEditorialCard extends StatelessWidget {
  final HealthVideo video;
  final VoidCallback onPlay;
  final VoidCallback onToggleSave;

  const _HealthVideoEditorialCard({
    required this.video,
    required this.onPlay,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return SeniorCard(
      onTap: onPlay,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              height: 188,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (video.thumbnailUrl.startsWith('assets/'))
                    Image.asset(video.thumbnailUrl, fit: BoxFit.cover)
                  else
                    Container(color: AppColors.iceBannerEnd),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x220F172A),
                          Color(0x990F172A),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        video.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        video.durationLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Xem hướng dẫn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            video.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
              color: AppColors.iceTextNavy,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            video.instructorName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            video.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.iceTextSlate,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SeniorActionButton(
                  label: 'Mở bài tập này',
                  icon: Icons.play_circle_outline_rounded,
                  variant: SeniorButtonVariant.primary,
                  onPressed: onPlay,
                ),
              ),
              const SizedBox(width: 10),
              SeniorLabeledIconButton(
                icon: video.isSaved
                    ? Icons.bookmark_rounded
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
