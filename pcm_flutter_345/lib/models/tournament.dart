import 'package:flutter/material.dart';

class Tournament {
  final int id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationDeadline;
  final String format;
  final double entryFee;
  final double prizePool;
  String status;
  final String? settings;
  int? participantCount;
  final int maxParticipants;
  final bool isJoined;
  final DateTime? createdDate;
  final String? createdBy;

  Tournament({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.registrationDeadline,
    required this.format,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    this.settings,
    this.participantCount = 0,
    this.maxParticipants = 32,
    this.isJoined = false,
    this.createdDate,
    this.createdBy,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      registrationDeadline: json['registrationDeadline'] != null 
          ? DateTime.parse(json['registrationDeadline']) 
          : null,
      format: json['format'] ?? 'RoundRobin',
      entryFee: json['entryFee']?.toDouble() ?? 0.0,
      prizePool: json['prizePool']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Open',
      settings: json['settings'],
      participantCount: json['participantCount'] ?? 0,
      maxParticipants: json['maxParticipants'] ?? 32,
      isJoined: json['isJoined'] ?? false,
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : null,
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'format': format,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'status': status,
      'settings': settings,
      'participantCount': participantCount,
      'maxParticipants': maxParticipants,
      'isJoined': isJoined,
      'createdDate': createdDate?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  String get formatDisplayName {
    switch (format) {
      case 'RoundRobin':
        return 'Vòng tròn';
      case 'Knockout':
        return 'Loại trực tiếp';
      case 'Hybrid':
        return 'Kết hợp';
      default:
        return format;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'Open':
        return 'Mở đăng ký';
      case 'Registering':
        return 'Đang đăng ký';
      case 'DrawCompleted':
        return 'Đã bốc thăm';
      case 'Ongoing':
        return 'Đang diễn ra';
      case 'Finished':
        return 'Đã kết thúc';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'Open':
      case 'Registering':
        return Colors.green;
      case 'DrawCompleted':
        return Colors.blue;
      case 'Ongoing':
        return Colors.orange;
      case 'Finished':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  bool get canJoin {
    return ['Open', 'Registering'].contains(status);
  }

  bool get canLeave {
    return ['Open', 'Registering'].contains(status);
  }

  bool get isUpcoming {
    return startDate.isAfter(DateTime.now());
  }

  bool get isOngoing {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now);
  }

  bool get isFinished {
    return endDate.isBefore(DateTime.now()) || status == 'Finished';
  }

  int get daysUntilStart {
    if (startDate.isBefore(DateTime.now())) return 0;
    return startDate.difference(DateTime.now()).inDays;
  }

  String get timeUntilStart {
    if (startDate.isBefore(DateTime.now())) return 'Đã bắt đầu';
    
    final difference = startDate.difference(DateTime.now());
    if (difference.inDays > 0) {
      return 'Còn ${difference.inDays} ngày';
    } else if (difference.inHours > 0) {
      return 'Còn ${difference.inHours} giờ';
    } else if (difference.inMinutes > 0) {
      return 'Còn ${difference.inMinutes} phút';
    } else {
      return 'Sắp bắt đầu';
    }
  }
}

class TournamentParticipant {
  final int id;
  final int tournamentId;
  final int memberId;
  final String memberName;
  final String? teamName;
  String paymentStatus;
  final DateTime joinedDate;
  final double? duprRating;

  TournamentParticipant({
    required this.id,
    required this.tournamentId,
    required this.memberId,
    required this.memberName,
    this.teamName,
    required this.paymentStatus,
    required this.joinedDate,
    this.duprRating,
  });

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      id: json['id'],
      tournamentId: json['tournamentId'],
      memberId: json['memberId'],
      memberName: json['memberName'] ?? '',
      teamName: json['teamName'],
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      joinedDate: DateTime.parse(json['joinedDate']),
      duprRating: json['duprRating']?.toDouble(),
    );
  }

  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case 'Pending':
        return 'Chờ thanh toán';
      case 'Paid':
        return 'Đã thanh toán';
      case 'Failed':
        return 'Thanh toán thất bại';
      default:
        return paymentStatus;
    }
  }

  Color get paymentStatusColor {
    switch (paymentStatus) {
      case 'Pending':
        return Colors.orange;
      case 'Paid':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class Match {
  int id;
  int? tournamentId;
  String roundName;
  DateTime? date;
  DateTime? startTime;
  int? team1Player1Id;
  int? team1Player2Id;
  int? team2Player1Id;
  int? team2Player2Id;
  String? team1Player1Name;
  String? team1Player2Name;
  String? team2Player1Name;
  String? team2Player2Name;
  int? score1;
  int? score2;
  String? details;
  String? winningSide;
  bool isRanked;
  String status;
  String? courtName;

  Match({
    required this.id,
    this.tournamentId,
    required this.roundName,
    this.date,
    this.startTime,
    this.team1Player1Id,
    this.team1Player2Id,
    this.team2Player1Id,
    this.team2Player2Id,
    this.team1Player1Name,
    this.team1Player2Name,
    this.team2Player1Name,
    this.team2Player2Name,
    this.score1,
    this.score2,
    this.details,
    this.winningSide,
    this.isRanked = true,
    required this.status,
    this.courtName,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      tournamentId: json['tournamentId'],
      roundName: json['roundName'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      team1Player1Id: json['team1Player1Id'],
      team1Player2Id: json['team1Player2Id'],
      team2Player1Id: json['team2Player1Id'],
      team2Player2Id: json['team2Player2Id'],
      team1Player1Name: json['team1Player1Name'] ?? json['team1Display'],
      team1Player2Name: json['team1Player2Name'],
      team2Player1Name: json['team2Player1Name'] ?? json['team2Display'],
      team2Player2Name: json['team2Player2Name'],
      score1: json['score1'],
      score2: json['score2'],
      details: json['details'],
      winningSide: json['winningSide'],
      isRanked: json['isRanked'] ?? true,
      status: json['status'] ?? 'Scheduled',
      courtName: json['courtName'],
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'Scheduled':
        return 'Đã lên lịch';
      case 'InProgress':
        return 'Đang diễn ra';
      case 'Finished':
        return 'Đã kết thúc';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;
      case 'InProgress':
        return Colors.orange;
      case 'Finished':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get team1Display {
    if (team1Player2Name != null) {
      return '$team1Player1Name & $team1Player2Name';
    }
    return team1Player1Name ?? 'TBD';
  }

  String get team2Display {
    if (team2Player2Name != null) {
      return '$team2Player1Name & $team2Player2Name';
    }
    return team2Player1Name ?? 'TBD';
  }

  String get scoreDisplay {
    if (score1 != null && score2 != null) {
      return '$score1 - $score2';
    }
    return 'vs';
  }

  bool get hasResult {
    return score1 != null && score2 != null;
  }

  String? get winnerDisplay {
    if (!hasResult) return null;
    
    if (winningSide == 'Team1') {
      return team1Display;
    } else if (winningSide == 'Team2') {
      return team2Display;
    }
    return null;
  }
}