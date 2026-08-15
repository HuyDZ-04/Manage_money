import 'package:flutter/material.dart';

/// Ba loại phí mà app theo dõi mỗi tháng.
enum FeeType { electricity, room, management }

/// Các khoản nhỏ nằm trong "tiền quản lý".
class ManagementItem {
  final String key;
  final String label;
  final IconData icon;

  const ManagementItem(this.key, this.label, this.icon);
}

const List<ManagementItem> kManagementItems = [
  ManagementItem('water', 'Tiền nước', Icons.water_drop_outlined),
  ManagementItem('parking', 'Tiền xe', Icons.two_wheeler_outlined),
  ManagementItem('building', 'Quản lý toà nhà', Icons.apartment_outlined),
  ManagementItem('other', 'Khoản khác', Icons.more_horiz),
];

extension FeeTypeX on FeeType {
  String get key => name;

  String get label {
    switch (this) {
      case FeeType.electricity:
        return 'Tiền điện';
      case FeeType.room:
        return 'Tiền phòng';
      case FeeType.management:
        return 'Tiền quản lý';
    }
  }

  String get subtitle {
    switch (this) {
      case FeeType.electricity:
        return 'Điện tiêu thụ trong tháng';
      case FeeType.room:
        return 'Tiền thuê phòng';
      case FeeType.management:
        return 'Nước, xe, quản lý toà nhà';
    }
  }

  IconData get icon {
    switch (this) {
      case FeeType.electricity:
        return Icons.bolt;
      case FeeType.room:
        return Icons.meeting_room_outlined;
      case FeeType.management:
        return Icons.apartment_outlined;
    }
  }

  /// Chỉ "tiền quản lý" mới có bảng chi tiết các khoản nhỏ.
  bool get hasBreakdown => this == FeeType.management;
}

FeeType feeTypeFromKey(String key) {
  return FeeType.values.firstWhere(
    (e) => e.name == key,
    orElse: () => FeeType.room,
  );
}

/// Hình thức thanh toán.
enum PaymentMethod { transfer, cash, ewallet, other }

extension PaymentMethodX on PaymentMethod {
  String get key => name;

  String get label {
    switch (this) {
      case PaymentMethod.transfer:
        return 'Chuyển khoản';
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.ewallet:
        return 'Ví điện tử';
      case PaymentMethod.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.transfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.ewallet:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }
}

PaymentMethod paymentMethodFromKey(String? key) {
  if (key == null) return PaymentMethod.transfer;
  return PaymentMethod.values.firstWhere(
    (e) => e.name == key,
    orElse: () => PaymentMethod.transfer,
  );
}
