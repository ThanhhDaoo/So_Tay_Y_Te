import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';

/// Helper widget hiển thị an toàn ảnh đại diện từ Network, File cục bộ hoặc Asset dự phòng.
Widget buildSafeAvatarImage({
  required String imageSource,
  required String fallbackAsset,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
}) {
  if (imageSource.startsWith('http://') || imageSource.startsWith('https://')) {
    return Image.network(
      imageSource,
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

  final file = File(imageSource);
  if (file.existsSync()) {
    return Image.file(
      file,
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
    imageSource.isNotEmpty ? imageSource : fallbackAsset,
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
  required Function(String localPath) onAvatarSaved,
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
      final ext = picked.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
      onAvatarSaved(savedFile.path);
    }
  } catch (e) {
    debugPrint('Error picking avatar: $e');
  }
}
