import '../../../../domain/entities/daily_health_task.dart';
import '../../../../domain/entities/daily_vital_log.dart';
import '../../../../domain/entities/medication_popup_reminder.dart';

class HomeHealthOverviewSummary {
  final String bloodType;
  final String heightWeightText;
  final String bmiStatusText;
  final List<String> chronicConditions;
  final List<String> allergies;
  final String latestCheckupSummary;

  const HomeHealthOverviewSummary({
    this.bloodType = 'Chưa rõ',
    this.heightWeightText = 'Chưa cập nhật chiều cao / cân nặng',
    this.bmiStatusText = 'Chưa tính BMI',
    this.chronicConditions = const [],
    this.allergies = const [],
    this.latestCheckupSummary = 'Chưa có đợt khám nào được ghi nhận.',
  });
}

class HomeState {
  final bool isLoading;
  final String fullName;
  final String ageLabel;
  final String genderLabel;
  final String? avatarPath;
  final String memberRoleLabel;
  final YesterdayTodayBpComparison bpComparison;
  final TodayMedicationProgress medicationProgress;
  final List<DailyHealthTask> todayTasks;
  final HomeHealthOverviewSummary healthOverview;
  final bool shouldAutoPromptMedication;
  final String? feedbackMessage;

  const HomeState({
    this.isLoading = false,
    this.fullName = 'Bác Nguyễn Văn An',
    this.ageLabel = '62 tuổi',
    this.genderLabel = 'Nam',
    this.avatarPath,
    this.memberRoleLabel = 'Hồ sơ chính',
    this.bpComparison = const YesterdayTodayBpComparison(),
    this.medicationProgress = const TodayMedicationProgress(
      completedSlots: 0,
      totalSlots: 3,
      allSlots: [],
    ),
    this.todayTasks = const [],
    this.healthOverview = const HomeHealthOverviewSummary(),
    this.shouldAutoPromptMedication = false,
    this.feedbackMessage,
  });

  int get completedTasksCount => todayTasks.where((t) => t.isCompleted).length;

  HomeState copyWith({
    bool? isLoading,
    String? fullName,
    String? ageLabel,
    String? genderLabel,
    String? avatarPath,
    String? memberRoleLabel,
    YesterdayTodayBpComparison? bpComparison,
    TodayMedicationProgress? medicationProgress,
    List<DailyHealthTask>? todayTasks,
    HomeHealthOverviewSummary? healthOverview,
    bool? shouldAutoPromptMedication,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      fullName: fullName ?? this.fullName,
      ageLabel: ageLabel ?? this.ageLabel,
      genderLabel: genderLabel ?? this.genderLabel,
      avatarPath: avatarPath ?? this.avatarPath,
      memberRoleLabel: memberRoleLabel ?? this.memberRoleLabel,
      bpComparison: bpComparison ?? this.bpComparison,
      medicationProgress: medicationProgress ?? this.medicationProgress,
      todayTasks: todayTasks ?? this.todayTasks,
      healthOverview: healthOverview ?? this.healthOverview,
      shouldAutoPromptMedication:
          shouldAutoPromptMedication ?? this.shouldAutoPromptMedication,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}
