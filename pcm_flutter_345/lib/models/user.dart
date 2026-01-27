import 'package:flutter/material.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? role;
  final String? avatarUrl;
  final Member? member;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.role,
    this.avatarUrl,
    this.member,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      avatarUrl: json['avatarUrl'],
      member: json['member'] != null ? Member.fromJson(json['member']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'avatarUrl': avatarUrl,
      'member': member?.toJson(),
    };
  }
}

class Member {
  final int id;
  final String fullName;
  final DateTime joinDate;
  final double rankLevel;
  final bool isActive;
  final double walletBalance;
  final String tier;
  final double totalSpent;
  final String? avatarUrl;

  Member({
    required this.id,
    required this.fullName,
    required this.joinDate,
    required this.rankLevel,
    required this.isActive,
    required this.walletBalance,
    required this.tier,
    required this.totalSpent,
    this.avatarUrl,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      fullName: json['fullName'],
      joinDate: DateTime.parse(json['joinDate']),
      rankLevel: json['rankLevel']?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
      walletBalance: json['walletBalance']?.toDouble() ?? 0.0,
      tier: json['tier'] ?? 'Standard',
      totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'joinDate': joinDate.toIso8601String(),
      'rankLevel': rankLevel,
      'isActive': isActive,
      'walletBalance': walletBalance,
      'tier': tier,
      'totalSpent': totalSpent,
      'avatarUrl': avatarUrl,
    };
  }

  String get tierDisplayName {
    switch (tier) {
      case 'Standard':
        return 'Đồng';
      case 'Silver':
        return 'Bạc';
      case 'Gold':
        return 'Vàng';
      case 'Diamond':
        return 'Kim Cương';
      default:
        return 'Đồng';
    }
  }

  Color get tierColor {
    switch (tier) {
      case 'Standard':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Diamond':
        return const Color(0xFFB9F2FF);
      default:
        return const Color(0xFFCD7F32);
    }
  }
}