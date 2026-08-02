import 'package:flutter/material.dart';
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

class _PaymentSelectionPageState extends State<PaymentSelectionPage> {
  String _selectedMethod = 'BCA';

  final List<Map<String, String>> _bankMethods = [
    {'code': 'BNI', 'name': 'BNI'},
    {'code': 'MANDIRI', 'name': 'Mandiri'},
    {'code': 'BRI', 'name': 'BRI'},
    {'code': 'BCA', 'name': 'BCA'},
    {'code': 'BSI', 'name': 'BSI'},
    {'code': 'CIMB', 'name': 'CIMB'},
    {'code': 'PERMATA', 'name': 'Permata'},
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'IDR ', decimalDigits: 0);
    final formattedAmount = currencyFormat.format(widget.amount);

    final expiryTime = DateTime.now().add(const Duration(hours: 24));
    final formattedExpiry = DateFormat('dd MMMM yyyy PUKUL HH:mm', 'id_ID').format(expiryTime).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'BAYAR SEBELUM',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedExpiry,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      formattedAmount,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'METODE PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Bank Transfer List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                  title: const Text(
                    'Transfer Bank',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  children: [
                    for (final bank in _bankMethods)
                      RadioListTile<String>(
                        value: bank['code']!,
                        groupValue: _selectedMethod,
                        activeColor: AppColors.pink,
                        onChanged: (val) => setState(() => _selectedMethod = val!),
                        title: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  bank['code']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: bank['code'] == 'BCA'
                                        ? Colors.blue.shade900
                                        : (bank['code'] == 'BNI' ? Colors.orange.shade800 : Colors.teal.shade800),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              bank['name']!,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // QRIS & E-Wallet
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: RadioListTile<String>(
                  value: 'QRIS',
                  groupValue: _selectedMethod,
                  activeColor: AppColors.pink,
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                  title: const Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                      SizedBox(width: 16),
                      Text('QRIS / E-Wallet (GoPay, OVO, ShopeePay)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _showPaymentSuccessDialog(context);
                  },
                  child: const Text('Bayar Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white, size: 36),
            ),
            SizedBox(height: 12),
            Text('Instruksi Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Silakan lakukan transfer via $_selectedMethod sebesar ${widget.amount.toStringAsFixed(0)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('No. Virtual Account:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('880123984712093', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/schedule');
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
