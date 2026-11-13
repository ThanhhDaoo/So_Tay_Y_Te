import 'package:flutter/foundation.dart';
import 'vital_reports_state.dart';

class VitalReportsViewModel extends ChangeNotifier {
  VitalReportsState _state = const VitalReportsState();

  VitalReportsState get state => _state;

  void selectMetric(VitalMetricType metric) {
    if (_state.selectedMetric == metric) return;
    _state = _state.copyWith(selectedMetric: metric);
    notifyListeners();
  }

  void selectTimeframe(VitalTimeframe timeframe) {
    if (_state.selectedTimeframe == timeframe) return;
    _state = _state.copyWith(selectedTimeframe: timeframe);
    notifyListeners();
  }

  Future<void> exportPdf() async {
    _state = _state.copyWith(
      exportingAction: ExportActionType.pdf,
      notificationMessage: 'Đang khởi tạo tài liệu PDF chuẩn A4 HL7/FHIR...',
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    _state = _state.copyWith(
      exportingAction: ExportActionType.none,
      notificationMessage: 'Đã xuất file PDF hồ sơ y tế thành công (#MV-892401.pdf)!',
    );
    notifyListeners();
  }

  Future<void> printAirPrint() async {
    _state = _state.copyWith(
      exportingAction: ExportActionType.print,
      notificationMessage: 'Đang kết nối tới máy in AirPrint y tế...',
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    _state = _state.copyWith(
      exportingAction: ExportActionType.none,
      notificationMessage: 'Lệnh in AirPrint khổ A4 đã được gửi thành công.',
    );
    notifyListeners();
  }

  Future<void> sendDoctor() async {
    _state = _state.copyWith(
      exportingAction: ExportActionType.sendDoctor,
      notificationMessage: 'Đang gửi hồ sơ sinh hiệu tới TS.BS. Lê Quang Minh...',
    );
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _state = _state.copyWith(
      exportingAction: ExportActionType.none,
      notificationMessage: 'Đã chuyển tiếp hồ sơ lâm sàng tới Bác sĩ điều trị!',
    );
    notifyListeners();
  }

  void clearNotification() {
    _state = _state.copyWith(notificationMessage: null);
    notifyListeners();
  }
}

