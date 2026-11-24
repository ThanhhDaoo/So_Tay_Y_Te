enum AuthIdentifierType {
  email,
  phone,
  patientCode,
  unknown,
}

class InputValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Chấp nhận SĐT di động Việt Nam: 03x, 05x, 07x, 08x, 09x (10 số),
  /// hoặc +84 / 84 theo sau bởi 9 số, hoặc 9 số (khi nhập cạnh đầu số +84).
  static final RegExp _vnPhoneStrictRegex = RegExp(
    r'^(?:(?:\+?84|0)[35789][0-9]{8}|[35789][0-9]{8})$',
  );

  static final RegExp _patientCodeRegex = RegExp(
    r'^styt-[a-z0-9]{4,12}$',
    caseSensitive: false,
  );

  /// Loại bỏ khoảng trắng, dấu gạch ngang, dấu chấm, dấu ngoặc trong SĐT
  static String stripPhoneSeparators(String input) {
    return input.trim().replaceAll(RegExp(r'[\s.\-()]+'), '');
  }

  /// Phân loại chuỗi định danh người dùng nhập vào
  static AuthIdentifierType classifyIdentifier(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return AuthIdentifierType.unknown;

    if (_patientCodeRegex.hasMatch(trimmed)) {
      return AuthIdentifierType.patientCode;
    }

    if (_emailRegex.hasMatch(trimmed)) {
      return AuthIdentifierType.email;
    }

    final compact = stripPhoneSeparators(trimmed);
    if (_vnPhoneStrictRegex.hasMatch(compact)) {
      return AuthIdentifierType.phone;
    }

    return AuthIdentifierType.unknown;
  }

  /// Chuẩn hóa SĐT Việt Nam về dạng quốc tế E.164 (+84xxxxxxxxx)
  static String normalizePhoneE164(String phone) {
    final cleaned = stripPhoneSeparators(phone);
    if (cleaned.startsWith('+84') && cleaned.length == 12) {
      return cleaned;
    }
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.startsWith('84') && cleaned.length == 11) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+84${cleaned.substring(1)}';
    }
    if (cleaned.length == 9 && RegExp(r'^[35789][0-9]{8}$').hasMatch(cleaned)) {
      return '+84$cleaned';
    }
    return '+84$cleaned';
  }

  /// Chuẩn hóa SĐT Việt Nam về dạng nội địa 10 chữ số (0xxxxxxxxx)
  static String normalizePhoneLocal(String phone) {
    final cleaned = stripPhoneSeparators(phone);
    if (cleaned.startsWith('+84') && cleaned.length == 12) {
      return '0${cleaned.substring(3)}';
    }
    if (cleaned.startsWith('84') && cleaned.length == 11) {
      return '0${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return cleaned;
    }
    if (cleaned.length == 9 && RegExp(r'^[35789][0-9]{8}$').hasMatch(cleaned)) {
      return '0$cleaned';
    }
    return cleaned;
  }

  /// Che bớt thông tin liên hệ để hiển thị xác minh danh tính (VD: 091***5678, tha***@gmail.com)
  static String maskContact(String contact) {
    final trimmed = contact.trim();
    if (trimmed.contains('@')) {
      final parts = trimmed.split('@');
      final local = parts.first;
      final domain = parts.last;
      if (local.length <= 2) {
        return '${local[0]}***@$domain';
      }
      return '${local.substring(0, 3)}***@$domain';
    }
    final localPhone = normalizePhoneLocal(trimmed);
    if (localPhone.length >= 9) {
      return '${localPhone.substring(0, 3)}***${localPhone.substring(localPhone.length - 3)}';
    }
    return trimmed;
  }

  static String? validateRequired(
    String? value, [
    String message = 'Trường này không được để trống',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên chủ hồ sơ';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Họ và tên phải có tối thiểu 2 ký tự';
    }
    if (RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return 'Họ và tên không hợp lệ';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ Email';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Địa chỉ Email không đúng định dạng';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final compact = stripPhoneSeparators(value);
    if (!_vnPhoneStrictRegex.hasMatch(compact)) {
      return 'Số điện thoại di động Việt Nam không hợp lệ (VD: 0912345678)';
    }
    return null;
  }

  /// Kiểm tra đầu vào cho Đăng ký: Chấp nhận Email hợp lệ HOẶC SĐT Việt Nam hợp lệ
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập Số điện thoại hoặc Email';
    }
    final trimmed = value.trim();
    // Nếu có ký tự @ hoặc chữ cái -> kiểm tra như Email
    if (trimmed.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      if (!_emailRegex.hasMatch(trimmed)) {
        return 'Địa chỉ Email không hợp lệ (VD: ten@gmail.com)';
      }
      return null;
    }
    // Ngược lại kiểm tra chuẩn SĐT Việt Nam
    final compact = stripPhoneSeparators(trimmed);
    if (!_vnPhoneStrictRegex.hasMatch(compact)) {
      return 'Số điện thoại không hợp lệ (gồm 10 số, đầu 03/05/07/08/09)';
    }
    return null;
  }

  /// Kiểm tra đầu vào cho Đăng nhập: SĐT, Email hoặc Mã hồ sơ STYT-XXXXXX
  static String? validateLoginIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập SĐT, Email hoặc Mã hồ sơ';
    }
    final type = classifyIdentifier(value);
    if (type == AuthIdentifierType.unknown) {
      final trimmed = value.trim();
      if (trimmed.toUpperCase().startsWith('STYT')) {
        return 'Mã hồ sơ phải có định dạng STYT-XXXXXX';
      }
      if (trimmed.contains('@')) {
        return 'Địa chỉ Email không đúng định dạng';
      }
      return 'SĐT, Email hoặc Mã hồ sơ không hợp lệ';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có tối thiểu 6 ký tự';
    }
    return null;
  }

  /// Kiểm tra định dạng Huyết áp (tùy chọn): SYS/DIA (VD: 120/80)
  static String? validateBloodPressure(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final clean = value.trim();
    final parts = clean.split('/');
    if (parts.length != 2) {
      return 'Nhập theo dạng Tâm thu/Tâm trương (VD: 120/80)';
    }
    final sys = int.tryParse(parts[0].trim());
    final dia = int.tryParse(parts[1].trim());
    if (sys == null || dia == null || sys < 40 || sys > 300 || dia < 20 || dia > 200) {
      return 'Chỉ số huyết áp ngoài ngưỡng sinh học (40-300 / 20-200)';
    }
    if (sys <= dia) {
      return 'Huyết áp tâm thu phải lớn hơn tâm trương';
    }
    return null;
  }

  /// Kiểm tra Nhịp tim (tùy chọn): 25 - 260 bpm
  static String? validateHeartRate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final hr = int.tryParse(value.trim());
    if (hr == null || hr < 25 || hr > 260) {
      return 'Nhịp tim hợp lệ từ 25 đến 260 bpm';
    }
    return null;
  }

  /// Kiểm tra Chiều cao (tùy chọn): 30 - 260 cm
  static String? validateHeightCm(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final h = double.tryParse(value.trim().replaceAll(',', '.'));
    if (h == null || h < 30 || h > 260) {
      return 'Chiều cao hợp lệ: 30 - 260 cm';
    }
    return null;
  }

  /// Kiểm tra Cân nặng (tùy chọn): 1 - 350 kg
  static String? validateWeightKg(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final w = double.tryParse(value.trim().replaceAll(',', '.'));
    if (w == null || w < 1 || w > 350) {
      return 'Cân nặng hợp lệ: 1 - 350 kg';
    }
    return null;
  }

  /// Kiểm tra SpO2 (tùy chọn): 50 - 100 %
  static String? validateSpo2(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final spo2 = int.tryParse(value.trim());
    if (spo2 == null || spo2 < 50 || spo2 > 100) {
      return 'SpO2 hợp lệ: 50 - 100%';
    }
    return null;
  }

  /// Kiểm tra Nhiệt độ cơ thể (tùy chọn): 32.0 - 44.0 °C
  static String? validateTemperature(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final temp = double.tryParse(value.trim().replaceAll(',', '.'));
    if (temp == null || temp < 32.0 || temp > 44.0) {
      return 'Nhiệt độ hợp lệ: 32.0 - 44.0 °C';
    }
    return null;
  }

  /// Kiểm tra Liên hệ khẩn cấp ICE (tùy chọn, nhưng nếu nhập phải có kèm SĐT hợp lệ để quay số cấp cứu)
  static String? validateEmergencyContact(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final clean = value.trim();
    if (clean.contains('@')) {
      return 'Vui lòng nhập số điện thoại (không nhập Email vào mục gọi khẩn cấp)';
    }
    final digits = clean.replaceAll(RegExp(r'\D'), '');
    if (digits == '115') return null;
    if (digits.length < 9 || digits.length > 12) {
      return 'Vui lòng nhập kèm số điện thoại hợp lệ (VD: Mẹ - 0912345678)';
    }
    return null;
  }

  /// Suy luận chính xác yếu tố Rh từ nhóm máu (O+, O-, AB-...)
  static String resolveRhFactor(String? bloodType) {
    if (bloodType == null) return 'Chưa rõ';
    final clean = bloodType.trim();
    if (clean.isEmpty || clean == 'Chưa rõ' || clean == '--') return 'Chưa rõ';
    if (clean.endsWith('-')) return 'Rh Âm';
    if (clean.endsWith('+')) return 'Rh Dương';
    return 'Chưa rõ';
  }
}
