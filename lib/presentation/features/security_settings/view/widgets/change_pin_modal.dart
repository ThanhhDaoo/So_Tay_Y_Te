import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

enum _PinModalStep { verifyOld, enterNew, confirmNew }

class ChangePinModal extends StatefulWidget {
  final VoidCallback onSuccess;
  final ValueChanged<String>? onPinCreated;
  final Future<bool> Function(String currentPin)? onVerifyCurrentPin;

  const ChangePinModal({
    super.key,
    required this.onSuccess,
    this.onPinCreated,
    this.onVerifyCurrentPin,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onSuccess,
    ValueChanged<String>? onPinCreated,
    Future<bool> Function(String currentPin)? onVerifyCurrentPin,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePinModal(
        onSuccess: onSuccess,
        onPinCreated: onPinCreated,
        onVerifyCurrentPin: onVerifyCurrentPin,
      ),
    );
  }

  @override
  State<ChangePinModal> createState() => _ChangePinModalState();
}

class _ChangePinModalState extends State<ChangePinModal> {
  String _pin = '';
  late _PinModalStep _step;
  String _firstPin = '';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _step = widget.onVerifyCurrentPin != null
        ? _PinModalStep.verifyOld
        : _PinModalStep.enterNew;
  }

  void _onKeyPress(String key) {
    if (_pin.length < 6) {
      setState(() {
        _pin += key;
        _errorText = null;
      });
      if (_pin.length == 6) {
        Future.delayed(const Duration(milliseconds: 180), () async {
          if (!mounted) return;
          if (_step == _PinModalStep.verifyOld) {
            final validOld = await widget.onVerifyCurrentPin!(_pin);
            if (!mounted) return;
            if (validOld) {
              setState(() {
                _pin = '';
                _errorText = null;
                _step = _PinModalStep.enterNew;
              });
            } else {
              setState(() {
                _pin = '';
                _errorText = 'Mã PIN hiện tại không đúng. Vui lòng thử lại!';
              });
            }
          } else if (_step == _PinModalStep.enterNew) {
            setState(() {
              _firstPin = _pin;
              _pin = '';
              _errorText = null;
              _step = _PinModalStep.confirmNew;
            });
          } else {
            if (_pin == _firstPin) {
              final confirmedPin = _pin;
              Navigator.pop(context);
              widget.onPinCreated?.call(confirmedPin);
              widget.onSuccess();
            } else {
              setState(() {
                _pin = '';
                _firstPin = '';
                _step = _PinModalStep.enterNew;
                _errorText = 'Mã PIN xác nhận không khớp. Vui lòng nhập lại!';
              });
            }
          }
        });
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    String title = 'Thiết Lập Mã PIN 6 Chữ Số';
    String subtitle = 'Mã PIN bảo mật giúp mở khóa Sổ Tay Y Tế khi không dùng Face ID';
    if (_step == _PinModalStep.verifyOld) {
      title = 'Xác Minh Mã PIN Hiện Tại';
      subtitle = 'Nhập mã PIN 6 chữ số đang sử dụng trước khi tạo mã PIN mới';
    } else if (_step == _PinModalStep.confirmNew) {
      title = 'Xác Nhận Mã PIN Mới';
      subtitle = 'Nhập lại mã PIN 6 số vừa tạo để xác nhận';
    }

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
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.iceTextNavy),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
          ),
          const SizedBox(height: 20),

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
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 24),

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
