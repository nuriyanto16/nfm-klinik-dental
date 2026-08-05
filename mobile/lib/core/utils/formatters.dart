import 'package:intl/intl.dart';

final _idrFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');
final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final _timeFormat = DateFormat('HH:mm', 'id_ID');

const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

String formatIDR(num amount) => _idrFormat.format(amount);

String formatDate(DateTime date) => _dateFormat.format(date.toLocal());

String formatDateTime(DateTime date) => _dateTimeFormat.format(date.toLocal());

String formatTime(DateTime date) => _timeFormat.format(date.toLocal());

String reservationStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Menunggu Konfirmasi';
    case 'confirmed':
      return 'Terkonfirmasi';
    case 'checked_in':
      return 'Check-in';
    case 'in_progress':
      return 'Sedang Ditangani';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    case 'no_show':
      return 'Tidak Hadir';
    default:
      return status;
  }
}

String paymentStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Menunggu Pembayaran';
    case 'paid':
      return 'Lunas';
    case 'expired':
      return 'Kedaluwarsa';
    case 'failed':
      return 'Gagal';
    case 'refunded':
      return 'Dikembalikan';
    default:
      return status;
  }
}

String formatTransactionId(String? id, [DateTime? createdAt]) {
  if (id == null || id.isEmpty) return 'TRX-00000000-0000';
  if (id.startsWith('TRX-') || id.startsWith('INV-')) return id;
  final date = createdAt ?? DateTime.now();
  final year = date.year.toString();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final clean = id.replaceAll('-', '').toUpperCase();
  final shortCode = clean.length >= 6 ? clean.substring(clean.length - 6) : clean.padLeft(6, '0');
  return 'TRX-$year$month$day-$shortCode';
}

