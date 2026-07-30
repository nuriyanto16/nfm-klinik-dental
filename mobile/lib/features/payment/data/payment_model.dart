class Payment {
  const Payment({
    required this.id,
    required this.reservationId,
    required this.patientId,
    required this.amount,
    required this.depositAmount,
    required this.status,
    required this.provider,
    this.providerReference,
    this.paymentMethod,
    this.paidAt,
    this.expiredAt,
    required this.createdAt,
    required this.patientName,
    required this.branchName,
  });

  final String id;
  final String reservationId;
  final String patientId;
  final double amount;
  final double depositAmount;
  final String status;
  final String provider;
  final String? providerReference;
  final String? paymentMethod;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final String patientName;
  final String branchName;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        reservationId: json['reservationId'] as String,
        patientId: json['patientId'] as String,
        amount: (json['amount'] as num).toDouble(),
        depositAmount: (json['depositAmount'] as num).toDouble(),
        status: json['status'] as String,
        provider: json['provider'] as String,
        providerReference: json['providerReference'] as String?,
        paymentMethod: json['paymentMethod'] as String?,
        paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
        expiredAt: json['expiredAt'] != null ? DateTime.parse(json['expiredAt'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        patientName: json['patientName'] as String,
        branchName: json['branchName'] as String,
      );
}
