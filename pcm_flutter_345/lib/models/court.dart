class Court {
  final int id;
  final String name;
  final String description;
  final double pricePerHour;
  final bool isActive;

  Court({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerHour,
    required this.isActive,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pricePerHour': pricePerHour,
      'isActive': isActive,
    };
  }
}

class TimeSlot {
  final String time;
  final bool isAvailable;
  final bool isReserved;
  final String? bookedBy;
  final String status; // 'available', 'reserved', 'booked'

  TimeSlot({
    required this.time,
    required this.isAvailable,
    required this.isReserved,
    this.bookedBy,
    required this.status,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      time: json['time'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      isReserved: json['isReserved'] ?? false,
      bookedBy: json['bookedBy'],
      status: json['status'] ?? 'available',
    );
  }
}

class CourtBooking {
  final int courtId;
  final String courtName;
  final DateTime date;
  final String timeSlot;
  final double price;
  final String status; // 'available', 'reserved', 'booked'
  final String? memberName;
  final DateTime? reservedUntil;

  CourtBooking({
    required this.courtId,
    required this.courtName,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.status,
    this.memberName,
    this.reservedUntil,
  });

  factory CourtBooking.fromJson(Map<String, dynamic> json) {
    return CourtBooking(
      courtId: json['courtId'] ?? 0,
      courtName: json['courtName'] ?? '',
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'available',
      memberName: json['memberName'],
      reservedUntil: json['reservedUntil'] != null 
          ? DateTime.parse(json['reservedUntil']) 
          : null,
    );
  }
}