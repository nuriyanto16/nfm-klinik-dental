import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class InsurancePage extends StatefulWidget {
  const InsurancePage({super.key});

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  final _noAsuransiController = TextEditingController();
  String? _selectedJaringan;
  String? _selectedAsuransi;
  bool _photoTaken = false;

  final List<String> _jaringanList = [
    'AdMedika',
    'Fullerton Health',
    'Medlinx',
    'InHealth',
  ];

  final List<String> _asuransiList = [
    'BPJS Kesehatan',
    'Prudential',
    'Manulife',
    'Allianz',
    'AXA Mandiri',
    'Generali',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Asuransi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Asuransi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Jaringan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedJaringan,
                decoration: const InputDecoration(
                  hintText: 'Cari Jaringan',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
                items: _jaringanList
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedJaringan = val),
              ),
              const SizedBox(height: 16),
              const Text(
                'Asuransi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAsuransi,
                decoration: const InputDecoration(
                  hintText: 'Cari Asuransi',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
                items: _asuransiList
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedAsuransi = val),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Asuransi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noAsuransiController,
                decoration: const InputDecoration(
                  hintText: 'No Asuransi',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kartu Asuransi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.pink),
                  ),
                  onPressed: () {
                    setState(() => _photoTaken = !_photoTaken);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_photoTaken ? 'Foto kartu asuransi berhasil diambil!' : 'Foto dibatalkan.'),
                      ),
                    );
                  },
                  icon: Icon(_photoTaken ? Icons.check_circle : Icons.camera_alt, color: AppColors.pink),
                  label: Text(
                    _photoTaken ? 'Foto Kartu Tersimpan' : 'Ambil Foto Kartu Asuransi',
                    style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_selectedAsuransi == null || _noAsuransiController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Silakan lengkapi data asuransi terlebih dahulu.')),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data asuransi berhasil dikonfirmasi!')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Konfirmasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
