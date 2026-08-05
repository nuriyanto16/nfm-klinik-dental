import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class PaymentSelectionPage extends StatefulWidget {
  const PaymentSelectionPage({super.key, this.amount = 100000, this.reservationId});

  final double amount;
  final String? reservationId;

  @override
  State<PaymentSelectionPage> createState() => _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends State<PaymentSelectionPage> with TickerProviderStateMixin {
  String _selectedMethod = 'BCA';
  bool _isPaying = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _bankMethods = [
    {'code': 'BNI', 'name': 'Bank BNI', 'color': Color(0xFFFF6600), 'logo': '🏛️'},
    {'code': 'MANDIRI', 'name': 'Bank Mandiri', 'color': Color(0xFF003087), 'logo': '🏦'},
    {'code': 'BRI', 'name': 'Bank BRI', 'color': Color(0xFF00529B), 'logo': '🏦'},
    {'code': 'BCA', 'name': 'Bank BCA', 'color': Color(0xFF005DAA), 'logo': '💳'},
    {'code': 'BSI', 'name': 'Bank BSI', 'color': Color(0xFF00855A), 'logo': '🕌'},
    {'code': 'CIMB', 'name': 'CIMB Niaga', 'color': Color(0xFFCC0000), 'logo': '🏦'},
    {'code': 'PERMATA', 'name': 'Bank Permata', 'color': Color(0xFF0033A0), 'logo': '💎'},
  ];

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'INV/${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}/$random';
  }

  String _generateVaNumber() {
    return '88012${Random().nextInt(99999999).toString().padLeft(8, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _methodColor {
    if (_selectedMethod == 'QRIS') return const Color(0xFF9C27B0);
    return _bankMethods.firstWhere((b) => b['code'] == _selectedMethod, orElse: () => {'color': AppColors.primary})['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'IDR ', decimalDigits: 0);
    final formattedAmount = currencyFormat.format(widget.amount);
    final expiryTime = DateTime.now().add(const Duration(hours: 24));
    final formattedExpiry = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(expiryTime);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Stack(
        children: [
          // Green header background
          Container(height: 60, color: AppColors.primary),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: [
                  // Amount Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top gradient strip
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.primary, AppColors.pink]),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Pembayaran', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedAmount,
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 14, color: Colors.orange.shade700),
                                        const SizedBox(width: 4),
                                        Text('24 Jam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFFEDF2F7)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Bayar sebelum: $formattedExpiry WIB',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.reservationId != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ID Reservasi: ${widget.reservationId!.length > 16 ? widget.reservationId!.substring(0, 16) + '...' : widget.reservationId}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section Title
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PILIH METODE PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bank Transfer Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: const Text(
                          'Transfer Bank',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark),
                        ),
                        subtitle: const Text('Virtual Account tersedia', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        children: [
                          const Divider(height: 1, color: Color(0xFFEDF2F7)),
                          for (final bank in _bankMethods)
                            _buildBankOption(bank),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // QRIS / E-Wallet Card
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'QRIS'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedMethod == 'QRIS' ? const Color(0xFF9C27B0) : Colors.transparent,
                          width: _selectedMethod == 'QRIS' ? 2 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF9C27B0), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('QRIS / E-Wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    _eWalletBadge('GoPay', Colors.green),
                                    const SizedBox(width: 4),
                                    _eWalletBadge('OVO', Colors.purple),
                                    const SizedBox(width: 4),
                                    _eWalletBadge('ShopeePay', Colors.orange),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: 'QRIS',
                            groupValue: _selectedMethod,
                            activeColor: const Color(0xFF9C27B0),
                            onChanged: (val) => setState(() => _selectedMethod = val!),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cash / Langsung
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'CASH'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedMethod == 'CASH' ? Colors.green.shade600 : Colors.transparent,
                          width: _selectedMethod == 'CASH' ? 2 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.payments_outlined, color: Colors.green.shade700, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bayar di Klinik', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
                                Text('Bayar tunai / kartu saat kunjungan', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: 'CASH',
                            groupValue: _selectedMethod,
                            activeColor: Colors.green.shade700,
                            onChanged: (val) => setState(() => _selectedMethod = val!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _isPaying ? null : _processPayment,
              style: FilledButton.styleFrom(
                backgroundColor: _methodColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isPaying
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                        SizedBox(width: 12),
                        Text('Memproses...', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                      ],
                    )
                  : Text('Bayar via $_selectedMethod', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankOption(Map<String, dynamic> bank) {
    final isSelected = _selectedMethod == bank['code'];
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = bank['code'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (bank['color'] as Color).withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: bank['code'] as String,
              groupValue: _selectedMethod,
              activeColor: bank['color'] as Color,
              visualDensity: VisualDensity.compact,
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            const SizedBox(width: 4),
            Container(
              width: 60,
              height: 36,
              decoration: BoxDecoration(
                color: (bank['color'] as Color).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (bank['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  bank['code'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: bank['color'] as Color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                bank['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (bank['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('VA Tersedia', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bank['color'] as Color)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eWalletBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isPaying = true);
    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://43.133.150.102:8092/api/v1'));
      final resId = widget.reservationId ?? 'a0c98df0-78ff-41d1-95f4-93cd5cf2c934';
      await dio.post('/payments', data: {
        'reservationId': resId,
        'amount': widget.amount > 0 ? widget.amount : 199000.0,
        'depositAmount': 0,
        'paymentMethod': _selectedMethod,
        'status': 'paid',
      });
      debugPrint('[Payment] Successfully posted payment to VPS API for reservation $resId');
    } catch (err) {
      debugPrint('[Payment] API error when posting payment: $err');
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isPaying = false);
    _showInvoiceSheet(context);
  }

  void _showInvoiceSheet(BuildContext context) {
    final invoiceNo = _generateInvoiceNumber();
    final vaNumber = _generateVaNumber();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(now);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.96,
        minChildSize: 0.6,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Success Header
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text('Instruksi Pembayaran', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text('Selesaikan pembayaran via $_selectedMethod', style: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w500)),

                      const SizedBox(height: 24),

                      // Invoice Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            // Invoice Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)]),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('BUKTI PEMBAYARAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text(invoiceNo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('MENUNGGU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.orange.shade800)),
                                  ),
                                ],
                              ),
                            ),
                            // Invoice Details
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _invoiceRow('Tanggal', formattedDate),
                                  _invoiceRow('Metode', _selectedMethod == 'QRIS' ? 'QRIS / E-Wallet' : 'Transfer Bank $_selectedMethod'),
                                  if (widget.reservationId != null)
                                    _invoiceRow('ID Reservasi', widget.reservationId!.length > 20 ? widget.reservationId!.substring(0, 20) + '...' : widget.reservationId!),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(color: Color(0xFFE2E8F0)),
                                  ),
                                  _invoiceRow('Total', currencyFormat.format(widget.amount), isTotal: true),
                                ],
                              ),
                            ),
                            // VA Number Box (for bank transfer)
                            if (_selectedMethod != 'QRIS' && _selectedMethod != 'CASH')
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Nomor Virtual Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(vaNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: 2)),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: vaNumber));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Nomor VA disalin!'), duration: Duration(seconds: 2)),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('Salin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            // QRIS Display
                            if (_selectedMethod == 'QRIS')
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.qr_code_2, size: 100, color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Scan QR dengan aplikasi dompet digital Anda', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Steps instruction
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text('Cara Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blue.shade700)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_selectedMethod != 'CASH' && _selectedMethod != 'QRIS') ...[
                              _stepItem('1', 'Buka aplikasi mobile banking $_selectedMethod Anda'),
                              _stepItem('2', 'Pilih menu Transfer / Virtual Account'),
                              _stepItem('3', 'Masukkan nomor Virtual Account di atas'),
                              _stepItem('4', 'Konfirmasi nominal & selesaikan transaksi'),
                              _stepItem('5', 'Simpan bukti transfer sebagai konfirmasi'),
                            ] else if (_selectedMethod == 'QRIS') ...[
                              _stepItem('1', 'Buka aplikasi GoPay / OVO / ShopeePay'),
                              _stepItem('2', 'Pilih menu Scan QR atau bayar'),
                              _stepItem('3', 'Arahkan kamera ke QR Code di atas'),
                              _stepItem('4', 'Konfirmasi pembayaran di aplikasi Anda'),
                            ] else ...[
                              _stepItem('1', 'Datang ke klinik sesuai jadwal reservasi'),
                              _stepItem('2', 'Tunjukkan ID Reservasi ini ke petugas'),
                              _stepItem('3', 'Lakukan pembayaran di kasir klinik'),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // CTA Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/schedule');
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 20),
                          label: const Text('Lihat Jadwal Reservasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.home_outlined, size: 20),
                          label: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 14 : 13, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, color: isTotal ? AppColors.textDark : AppColors.textMuted)),
          Text(value, style: TextStyle(fontSize: isTotal ? 16 : 13, fontWeight: FontWeight.w800, color: isTotal ? AppColors.primary : AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _stepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: Colors.blue.shade600, shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.blue.shade900, fontWeight: FontWeight.w500, height: 1.4))),
        ],
      ),
    );
  }
}
