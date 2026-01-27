import 'package:flutter/material.dart';

class Court {
  final int id;
  final String name;
  final bool isActive;
  final String? description;
  final double pricePerHour;

  Court({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
    required this.pricePerHour,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? true,
      description: json['description'],
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'description': description,
      'pricePerHour': pricePerHour,
    };
  }
}

class Booking {
  final int id;
  final int courtId;
  final int memberId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final int? transactionId;
  final bool isRecurring;
  final String? recurrenceRule;
  final int? parentBookingId;
  final String status;
  final Court? court;
  final String? memberName;

  Booking({
    required this.id,
    required this.courtId,
    required this.memberId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.transactionId,
    required this.isRecurring,
    this.recurrenceRule,
    this.parentBookingId,
    required this.status,
    this.court,
    this.memberName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      courtId: json['courtId'],
      memberId: json['memberId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
      transactionId: json['transactionId'],
      isRecurring: json['isRecurring'] ?? false,
      recurrenceRule: json['recurrenceRule'],
      parentBookingId: json['parentBookingId'],
      status: json['status'] ?? 'Confirmed',
      court: json['court'] != null ? Court.fromJson(json['court']) : null,
      memberName: json['memberName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courtId': courtId,
      'memberId': memberId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalPrice': totalPrice,
      'transactionId': transactionId,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'parentBookingId': parentBookingId,
      'status': status,
      'court': court?.toJson(),
      'memberName': memberName,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'PendingPayment':
        return 'Chờ thanh toán';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Cancelled':
        return 'Đã hủy';
      case 'Completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PendingPayment':
        return Colors.orange;
      case 'Confirmed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Duration get duration {
    return endTime.difference(startTime);
  }

  String get timeRange {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }
}