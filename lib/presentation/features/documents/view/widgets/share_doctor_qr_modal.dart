import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/database/database_helper.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/security/password_hasher.dart';
import '../../../../../core/services/user_session_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/clinical_qr_code_widget.dart';
import '../../../../../domain/repositories/auth_repository.dart';

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
  late final String _pinFormatted;
  late final String _pinRaw;
  late final String _shareToken;
  String _patientCode = 'STYT-PATIENT';
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    final rng = Random.secure();
    final part1 = (100 + rng.nextInt(900)).toString();
    final part2 = (100 + rng.nextInt(900)).toString();
    _pinFormatted = '$part1 - $part2';
    _pinRaw = '$part1$part2';
    _shareToken = const Uuid().v4();
    _initAndPersistToken();
  }

  String get _scopesCsv => <String>[
        if (_shareRx) 'RX',
        if (_shareBlood) 'LAB',
        if (_shareXray) 'IMG',
      ].join(',');

  Future<void> _initAndPersistToken() async {
    if (sl.isRegistered<AuthRepository>()) {
      try {
        final session = await sl<AuthRepository>().getActiveSession();
        if (session != null) {
          _activeUserId = session.id;
          if (mounted) {
            setState(() => _patientCode = session.patientCode);
          }
        }
      } catch (_) {}
    }
    await _persistOrUpdateToken(isRevoked: false);
  }

  Future<void> _persistOrUpdateToken({required bool isRevoked}) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24)).toIso8601String();
    final salt = PasswordHasher.generateSalt(16);
    final pinHash = '${PasswordHasher.hashPassword(_pinRaw, salt)}::$salt';
    final userId = _activeUserId ?? 'local_guest';
    final scopes = _scopesCsv;

    // 1. Lưu / cập nhật trong SQLite cục bộ (doctor_share_tokens)
    if (sl.isRegistered<DatabaseHelper>()) {
      try {
        final db = await sl<DatabaseHelper>().database;
        if (isRevoked) {
          await db.update(
            'doctor_share_tokens',
            {'is_revoked': 1},
            where: 'token = ?',
            whereArgs: [_shareToken],
          );
        } else {
          await db.insert(
            'doctor_share_tokens',
            {
              'token': _shareToken,
              'user_id': userId,
              'pin_code': pinHash,
              'scopes': scopes,
              'expires_at': expiresAt,
              'is_revoked': 0,
              'created_at': now.toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (_) {}
    }

    // 2. Đồng bộ token/thu hồi lên Supabase nếu đã đăng nhập Cloud
    final client = SupabaseConfig.client;
    final supaUid = client?.auth.currentUser?.id;
    if (client != null && supaUid != null) {
      try {
        if (isRevoked) {
          await client
              .from('doctor_share_tokens')
              .update({'is_revoked': true})
              .eq('token', _shareToken)
              .eq('user_id', supaUid);
        } else {
          await client.from('doctor_share_tokens').upsert({
            'token': _shareToken,
            'user_id': supaUid,
            'pin_hash': pinHash,
            'scopes': scopes.isEmpty ? <String>[] : scopes.split(','),
            'expires_at': expiresAt,
            'is_revoked': false,
          });
        }
      } catch (_) {}
    }
  }

  String get _qrPayload {
    final patientName = AppSessionNotifier.instance.fullName ?? 'BenhNhan';
    // Không nhúng PIN thô vào mã QR để đảm bảo xác thực 2 yếu tố (QR Token + PIN đọc trực tiếp cho Bác sĩ)
    return 'STYT://SHARE?code=$_patientCode&name=${Uri.encodeComponent(patientName)}&scopes=$_scopesCsv&token=$_shareToken';
  }

  void _onScopeChanged(void Function() update) {
    setState(update);
    _persistOrUpdateToken(isRevoked: false);
  }

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
                const Row(
                  children: [
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
                          child: Center(
                            child: ClinicalQrCodeWidget(
                              data: _qrPayload,
                              size: 168,
                              foregroundColor: AppColors.iceOliveDark,
                            ),
                          ),
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
                        children: [
                          const Text('Mã PIN xác thực bác sĩ:', style: TextStyle(fontSize: 12, color: AppColors.iceTextMuted)),
                          const SizedBox(height: 2),
                          Text(
                            _pinFormatted,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppColors.iceOliveDark),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _qrPayload));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã sao chép liên kết chia sẻ bảo mật (PIN: $_pinFormatted)!'),
                              backgroundColor: AppColors.iceOlive,
                              duration: const Duration(seconds: 1),
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
                  onChanged: (v) => _onScopeChanged(() => _shareRx = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Kết quả xét nghiệm máu (CBC)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('32 chỉ số huyết học đợt khám gần nhất', style: TextStyle(fontSize: 11, color: AppColors.iceTextSlate)),
                  value: _shareBlood,
                  activeColor: AppColors.iceOlive,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => _onScopeChanged(() => _shareBlood = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Hình ảnh chẩn đoán (Nội soi & X-Quang)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ảnh độ phân giải cao và kết luận của bác sĩ', style: TextStyle(fontSize: 11, color: AppColors.iceTextSlate)),
                  value: _shareXray,
                  activeColor: AppColors.iceOlive,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => _onScopeChanged(() => _shareXray = v ?? true),
                ),
                const SizedBox(height: 20),

                // Danger revoke button
                OutlinedButton.icon(
                  onPressed: () async {
                    await _persistOrUpdateToken(isRevoked: true);
                    if (!context.mounted) return;
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
