import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';

/// Helper quản lý và phân giải an toàn đường dẫn ảnh đại diện trên iOS & Android.
/// Đặc biệt xử lý trường hợp iOS thay đổi Sandbox Application UUID sau mỗi lần build/reinstall.
class SafeAvatarHelper {
  static String? documentsDirPath;

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      documentsDirPath = dir.path;
    } catch (_) {}
  }

  /// Tự động phân giải đường dẫn ảnh:
  /// Nếu đường dẫn chứa UUID cũ của iOS sandbox (sau khi rebuild ứng dụng)
  /// hoặc chỉ là tên file tương đối, hàm sẽ tìm file tương ứng trong thư mục Documents hiện tại.
  static String resolveImagePath(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return '';
    if (rawPath.startsWith('http://') ||
        rawPath.startsWith('https://') ||
        rawPath.startsWith('assets/')) {
      return rawPath;
    }

    final directFile = File(rawPath);
    if (directFile.existsSync()) return rawPath;

    final fileName = rawPath.split('/').last;
    if (fileName.isNotEmpty && documentsDirPath != null) {
      final currentFile = File('$documentsDirPath/$fileName');
      if (currentFile.existsSync()) {
        return currentFile.path;
      }
    }
    return rawPath;
  }
}

/// Helper widget hiển thị an toàn ảnh đại diện từ Network, File cục bộ hoặc Asset dự phòng.
Widget buildSafeAvatarImage({
  required String imageSource,
  required String fallbackAsset,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
}) {
  final resolvedSource = SafeAvatarHelper.resolveImagePath(imageSource);

  if (resolvedSource.startsWith('http://') || resolvedSource.startsWith('https://')) {
    return Image.network(
      resolvedSource,
      key: ValueKey(resolvedSource),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      ),
    );
  }

  final file = File(resolvedSource);
  if (file.existsSync()) {
    return Image.file(
      file,
      key: ValueKey(file.path),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
      ),
    );
  }

  return Image.asset(
    resolvedSource.isNotEmpty ? resolvedSource : fallbackAsset,
    key: ValueKey(resolvedSource),
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    errorBuilder: (_, _, _) => Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
    ),
  );
}

/// Mở popup cho người dùng chụp ảnh từ Camera hoặc chọn từ Thư viện ảnh,
/// sau đó sao chép vào bộ nhớ ứng dụng và gọi hàm callback với đường dẫn file.
Future<void> pickAndSaveAvatar(
  BuildContext context, {
  required Future<void> Function(String localPath) onAvatarSaved,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cập Nhật Ảnh Đại Diện',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.iceTextNavy,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.iceOlive),
              title: const Text('Chụp từ máy ảnh (Camera)'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.iceOlive),
              title: const Text('Chọn từ bộ sưu tập ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return;

  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      SafeAvatarHelper.documentsDirPath = appDir.path;
      final ext = picked.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
      await onAvatarSaved(savedFile.path);
    }
  } catch (e) {
    debugPrint('Error picking avatar: $e');
  }
}
