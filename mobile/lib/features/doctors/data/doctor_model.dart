class Doctor {
  const Doctor({required this.id, required this.fullName, this.specialization, this.photoUrl});

  final String id;
  final String fullName;
  final String? specialization;
  final String? photoUrl;

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        specialization: json['specialization'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );
}

class DoctorSchedule {
  const DoctorSchedule({
    required this.dayOfWeek,
    required this.branchId,
    required this.startTime,
    required this.endTime,
  });

  final int dayOfWeek;
  final String branchId;
  final String startTime;
  final String endTime;

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) => DoctorSchedule(
        dayOfWeek: json['dayOfWeek'] as int,
        branchId: json['branchId'] as String,
        startTime: (json['startTime'] as String).substring(0, 5),
        endTime: (json['endTime'] as String).substring(0, 5),
      );
}

class DoctorDetail extends Doctor {
  const DoctorDetail({
    required super.id,
    required super.fullName,
    super.specialization,
    super.photoUrl,
    required this.isActive,
    required this.branchIds,
    required this.schedules,
  });

  final bool isActive;
  final List<String> branchIds;
  final List<DoctorSchedule> schedules;

  factory DoctorDetail.fromJson(Map<String, dynamic> json) => DoctorDetail(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        specialization: json['specialization'] as String?,
        photoUrl: json['photoUrl'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        branchIds: (json['branchIds'] as List<dynamic>? ?? []).cast<String>(),
        schedules: (json['schedules'] as List<dynamic>? ?? [])
            .map((e) => DoctorSchedule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
