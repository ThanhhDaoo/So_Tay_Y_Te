abstract class ApiClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters});
  Future<dynamic> post(String path, {dynamic data});
}

class DioApiClient implements ApiClient {
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    // Implement Dio get
    return null;
  }

  @override
  Future<dynamic> post(String path, {dynamic data}) async {
    // Implement Dio post
    return null;
  }
}
