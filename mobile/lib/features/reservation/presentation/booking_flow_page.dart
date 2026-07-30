import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../branches/data/branch_repository.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../patient/application/session_controller.dart';
import '../../treatments/data/treatment_repository.dart';
import '../data/reservation_repository.dart';

class BookingFlowPage extends ConsumerStatefulWidget {
  const BookingFlowPage({super.key, this.initialBranchId, this.initialDoctorId});

  final String? initialBranchId;
  final String? initialDoctorId;

  @override
  ConsumerState<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends ConsumerState<BookingFlowPage> {
  int _step = 0;
  String? _branchId;
  String? _doctorId;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final Set<String> _treatmentIds = {};
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _branchId = widget.initialBranchId;
    _doctorId = widget.initialDoctorId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit(String patientId) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final scheduledAt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      await ref.read(reservationRepositoryProvider).createReservation(
            CreateReservationInput(
              patientId: patientId,
              branchId: _branchId!,
              staffId: _doctorId!,
              scheduledAt: scheduledAt,
              complaintNote: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
              treatmentIds: _treatmentIds.toList(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservasi berhasil dibuat! Menunggu konfirmasi klinik.')),
        );
        context.go('/reservations/history');
      }
    } catch (err) {
      setState(() => _error = apiErrorMessage(err));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).value;
    final branches = ref.watch(branchListProvider);
    final doctors = ref.watch(doctorListProvider);
    final treatments = ref.watch(treatmentListProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservasi')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                const Text('Lengkapi profil pasien dulu sebelum membuat reservasi.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.push('/register'), child: const Text('Lengkapi Profil')),
              ],
            ),
          ),
        ),
      );
    }

    final total = (treatments.value ?? []).where((t) => _treatmentIds.contains(t.id)).fold<double>(0, (sum, t) => sum + t.price);

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Reservasi')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0 && _branchId == null) return;
          if (_step == 1 && _doctorId == null) return;
          if (_step < 3) {
            setState(() => _step++);
          } else {
            _submit(session.patientId);
          }
        },
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              FilledButton(
                onPressed: _submitting ? null : details.onStepContinue,
                child: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_step == 3 ? 'Buat Reservasi' : 'Lanjut'),
              ),
              if (details.onStepCancel != null) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: details.onStepCancel, child: const Text('Kembali')),
              ],
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Pilih Cabang'),
            isActive: _step >= 0,
            state: _branchId != null ? StepState.complete : StepState.indexed,
            content: Column(
              children: (branches.value ?? [])
                  .map((b) => RadioListTile<String>(
                        value: b.id,
                        groupValue: _branchId,
                        title: Text(b.name),
                        subtitle: Text(b.city),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _branchId = v),
                      ))
                  .toList(),
            ),
          ),
          Step(
            title: const Text('Pilih Dokter'),
            isActive: _step >= 1,
            state: _doctorId != null ? StepState.complete : StepState.indexed,
            content: Column(
              children: (doctors.value ?? [])
                  .map((d) => RadioListTile<String>(
                        value: d.id,
                        groupValue: _doctorId,
                        title: Text(d.fullName),
                        subtitle: Text(d.specialization ?? 'Dokter Gigi Umum'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _doctorId = v),
                      ))
                  .toList(),
            ),
          ),
          Step(
            title: const Text('Jadwal & Keluhan'),
            isActive: _step >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(formatDate(_date)),
                  onTap: _pickDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text(_time.format(context)),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Keluhan (opsional)', alignLabelWithHint: true),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Rencana Perawatan'),
            isActive: _step >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...(treatments.value ?? []).map((t) => CheckboxListTile(
                      value: _treatmentIds.contains(t.id),
                      title: Text(t.name),
                      subtitle: Text(formatIDR(t.price)),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _treatmentIds.add(t.id);
                        } else {
                          _treatmentIds.remove(t.id);
                        }
                      }),
                    )),
                if (_treatmentIds.isNotEmpty) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimasi Total', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(formatIDR(total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
