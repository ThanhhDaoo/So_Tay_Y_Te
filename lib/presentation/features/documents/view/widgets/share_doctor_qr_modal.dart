import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ShareDoctorQrModal extends StatefulWidget {
  const ShareDoctorQrModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShareDoctorQrModal(),
    );
  }

  @override
  State<ShareDoctorQrModal> createState() => _ShareDoctorQrModalState();
}

class _ShareDoctorQrModalState extends State<ShareDoctorQrModal> {
  bool _shareRx = true;
  bool _shareBlood = true;
  bool _shareXray = true;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.qr_code_2, color: AppColors.iceOlive, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Chia Sẻ Hồ Sơ Cho Bác Sĩ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.iceTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.iceCardBorder),

          // Body
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
              children: [
                // QR Box
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.iceOlive.withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.iceOlive.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_2, size: 170, color: AppColors.iceOliveDark),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: Color(0xFF92400E)),
                              SizedBox(width: 6),
                              Text(
                                'Hiệu lực còn: 23 giờ 59 phút',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // PIN Access code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.iceCardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Mã PIN xác thực bác sĩ:', style: TextStyle(fontSize: 12, color: AppColors.iceTextMuted)),
                          SizedBox(height: 2),
                          Text(
                            '892 - 410',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.iceOliveDark),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép liên kết chia sẻ bảo mật!'),
                              backgroundColor: AppColors.iceOlive,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16, color: AppColors.iceOlive),
                        label: const Text('Sao chép link', style: TextStyle(color: AppColors.iceOlive, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Scopes
                const Text(
                  'Phạm Vi Dữ Liệu Được Chia Sẻ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Toa thuốc & Lịch uống hiện hành', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Bao gồm liều dùng và chống chỉ định dị ứng', style: TextStyle(fontSize: 11, color: AppColors.iceTextSlate)),
                  value: _shareRx,
                  activeColor: AppColors.iceOlive,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _shareRx = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Kết quả xét nghiệm máu (CBC)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('32 chỉ số huyết học đợt khám gần nhất', style: TextStyle(fontSize: 11, color: AppColors.iceTextSlate)),
                  value: _shareBlood,
                  activeColor: AppColors.iceOlive,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _shareBlood = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Hình ảnh chẩn đoán (Nội soi & X-Quang)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ảnh độ phân giải cao và kết luận của bác sĩ', style: TextStyle(fontSize: 11, color: AppColors.iceTextSlate)),
                  value: _shareXray,
                  activeColor: AppColors.iceOlive,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _shareXray = v ?? true),
                ),
                const SizedBox(height: 20),

                // Danger revoke button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thu hồi quyền truy cập mã QR thành công!'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.block, size: 18, color: Colors.redAccent),
                  label: const Text('Thu Hồi Quyền Truy Cập Ngay', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
