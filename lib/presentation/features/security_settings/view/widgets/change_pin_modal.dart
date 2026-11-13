import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ChangePinModal extends StatefulWidget {
  final VoidCallback onSuccess;

  const ChangePinModal({super.key, required this.onSuccess});

  static void show(BuildContext context, {required VoidCallback onSuccess}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePinModal(onSuccess: onSuccess),
    );
  }

  @override
  State<ChangePinModal> createState() => _ChangePinModalState();
}

class _ChangePinModalState extends State<ChangePinModal> {
  String _pin = '';
  bool _isConfirmStep = false;
  String _firstPin = '';

  void _onKeyPress(String key) {
    if (_pin.length < 6) {
      setState(() => _pin += key);
      if (_pin.length == 6) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          if (!_isConfirmStep) {
            setState(() {
              _firstPin = _pin;
              _pin = '';
              _isConfirmStep = true;
            });
          } else {
            if (_pin == _firstPin) {
              Navigator.pop(context);
              widget.onSuccess();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mã PIN không khớp. Vui lòng thử lại!'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              setState(() {
                _pin = '';
                _firstPin = '';
                _isConfirmStep = false;
              });
            }
          }
        });
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.shield_outlined, size: 36, color: AppColors.secOlive),
          const SizedBox(height: 12),
          Text(
            _isConfirmStep ? 'Xác Nhận Mã PIN Mới' : 'Thiết Lập Mã PIN 6 Chữ Số',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
          ),
          const SizedBox(height: 6),
          Text(
            _isConfirmStep
                ? 'Nhập lại mã PIN 6 số vừa tạo để xác nhận'
                : 'Mã PIN bảo mật giúp mở khóa Sổ Tay Y Tế khi không dùng Face ID',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
          ),
          const SizedBox(height: 24),

          // 6 PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.secOlive : Colors.transparent,
                  border: Border.all(color: AppColors.secOlive, width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Keypad
          for (var row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'delete'],
          ]) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 64, height: 56);
                if (key == 'delete') {
                  return SizedBox(
                    width: 64,
                    height: 56,
                    child: IconButton(
                      icon: const Icon(Icons.backspace_outlined, color: AppColors.iceTextNavy),
                      onPressed: _onDelete,
                    ),
                  );
                }
                return InkWell(
                  onTap: () => _onKeyPress(key),
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: 64,
                    height: 56,
                    alignment: Alignment.center,
                    child: Text(
                      key,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.iceTextNavy),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
