// Khởi tạo Dependency Injection (get_it / injectable)
class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  static Future<void> init() async {
    // Đăng ký Datasources, Repositories, UseCases, ViewModels
  }
}
