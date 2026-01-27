import 'package:flutter/material.dart';

class WalletTransaction {
  final int id;
  final int memberId;
  final double amount;
  final String type;
  final String status;
  final String? relatedId;
  final String description;
  final DateTime createdDate;
  final String? proofImageUrl;
  final String? adminNote;
  final String? memberName;

  WalletTransaction({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.type,
    required this.status,
    this.relatedId,
    required this.description,
    required this.createdDate,
    this.proofImageUrl,
    this.adminNote,
    this.memberName,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      memberId: json['memberId'],
      amount: json['amount']?.toDouble() ?? 0.0,
      type: json['type'],
      status: json['status'],
      relatedId: json['relatedId'],
      description: json['description'] ?? '',
      createdDate: DateTime.parse(json['createdDate']),
      proofImageUrl: json['proofImageUrl'],
      adminNote: json['adminNote'],
      memberName: json['memberName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'amount': amount,
      'type': type,
      'status': status,
      'relatedId': relatedId,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
      'proofImageUrl': proofImageUrl,
      'adminNote': adminNote,
      'memberName': memberName,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case 'Deposit':
        return 'Nạp tiền';
      case 'Withdraw':
        return 'Rút tiền';
      case 'Payment':
        return 'Thanh toán';
      case 'Refund':
        return 'Hoàn tiền';
      case 'Reward':
        return 'Thưởng';
      default:
        return type;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'Pending':
        return 'Chờ duyệt';
      case 'Completed':
        return 'Hoàn thành';
      case 'Rejected':
        return 'Từ chối';
      case 'Failed':
        return 'Thất bại';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'Deposit':
      case 'Refund':
      case 'Reward':
        return Colors.green;
      case 'Withdraw':
      case 'Payment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'Deposit':
        return Icons.add_circle;
      case 'Withdraw':
        return Icons.remove_circle;
      case 'Payment':
        return Icons.payment;
      case 'Refund':
        return Icons.refresh;
      case 'Reward':
        return Icons.card_giftcard;
      default:
        return Icons.account_balance_wallet;
    }
  }

  bool get isPositive {
    return ['Deposit', 'Refund', 'Reward'].contains(type);
  }

  String get formattedAmount {
    final sign = isPositive ? '+' : '-';
    return '$sign${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }
}