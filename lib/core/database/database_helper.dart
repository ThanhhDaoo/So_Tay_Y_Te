abstract class DatabaseHelper {
  Future<void> init();
  Future<void> close();
}

class AppDatabaseHelper implements DatabaseHelper {
  @override
  Future<void> init() async {
    // Khởi tạo SQLite / Drift / Isar database
  }

  @override
  Future<void> close() async {
    // Đóng kết nối database
  }
}
