class Reservation {
  const Reservation({
    required this.id,
    required this.patientId,
    required this.branchId,
    required this.staffId,
    required this.scheduledAt,
    required this.status,
    this.complaintNote,
    required this.patientName,
    required this.branchName,
    required this.doctorName,
    required this.treatments,
  });

  final String id;
  final String patientId;
  final String branchId;
  final String staffId;
  final DateTime scheduledAt;
  final String status;
  final String? complaintNote;
  final String patientName;
  final String branchName;
  final String doctorName;
  final String treatments;

  String get queueTicketNumber {
    if (id.startsWith('NDC-') || id.startsWith('ANT-') || id.startsWith('RES-')) {
      return id.toUpperCase();
    }
    final clean = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.length >= 6) {
      return 'NDC-${clean.substring(clean.length - 4).toUpperCase()}';
    }
    final match = RegExp(r'\d+').firstMatch(id);
    final num = match != null ? match.group(0)!.padLeft(3, '0') : '001';
    return 'NDC-$num';
  }

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as String? ?? 'res-${DateTime.now().millisecondsSinceEpoch}',
        patientId: json['patientId'] as String? ?? '',
        branchId: json['branchId'] as String? ?? '',
        staffId: json['staffId'] as String? ?? '',
        scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt'] as String) : DateTime.now(),
        status: json['status'] as String? ?? 'confirmed',
        complaintNote: json['complaintNote'] as String? ?? 'Pemeriksaan Rutin Gigi',
        patientName: json['patientName'] as String? ?? 'Pasien NDC',
        branchName: json['branchName'] as String? ?? 'NDC Cabang Soreang',
        doctorName: json['doctorName'] as String? ?? 'drg. Nina Marlina, Sp.KG',
        treatments: json['treatments'] as String? ?? 'Konsultasi & Perawatan Gigi',
      );
}
