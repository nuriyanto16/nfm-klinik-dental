class Doctor {
  const Doctor({required this.id, required this.fullName, this.specialization, this.photoUrl});

  final String id;
  final String fullName;
  final String? specialization;
  final String? photoUrl;

  static String resolveDoctorPhoto(String name, String? url) {
    if (url != null && url.trim().isNotEmpty && url.startsWith('http')) return url;
    if (name.contains('Friski') || name.contains('Fajar') || name.contains('Ahmad')) {
      return 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=800';
    }
    if (name.contains('Siti') || name.contains('Nina') || name.contains('Rina') || name.contains('Dewi')) {
      return 'https://images.unsplash.com/photo-1594824813571-24a69c100c3f?w=800';
    }
    return 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=800';
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final name = json['fullName'] as String? ?? 'drg. Nina Marlina, Sp.KG';
    final photo = json['photoUrl'] as String?;
    return Doctor(
      id: json['id'] as String? ?? '21000000-0000-0000-0000-000000000001',
      fullName: name,
      specialization: json['specialization'] as String? ?? 'Dokter Gigi Spesialis',
      photoUrl: resolveDoctorPhoto(name, photo),
    );
  }
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
        dayOfWeek: json['dayOfWeek'] as int? ?? 0,
        branchId: json['branchId'] as String? ?? '',
        startTime: (json['startTime'] as String? ?? '09:00:00').substring(0, 5),
        endTime: (json['endTime'] as String? ?? '17:00:00').substring(0, 5),
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

  factory DoctorDetail.fromJson(Map<String, dynamic> json) {
    final name = json['fullName'] as String? ?? 'drg. Nina Marlina, Sp.KG';
    final photo = json['photoUrl'] as String?;
    return DoctorDetail(
      id: json['id'] as String? ?? '21000000-0000-0000-0000-000000000001',
      fullName: name,
      specialization: json['specialization'] as String? ?? 'Dokter Gigi Spesialis',
      photoUrl: Doctor.resolveDoctorPhoto(name, photo),
      isActive: json['isActive'] as bool? ?? true,
      branchIds: (json['branchIds'] as List<dynamic>? ?? []).cast<String>(),
      schedules: (json['schedules'] as List<dynamic>? ?? [])
          .map((e) => DoctorSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
