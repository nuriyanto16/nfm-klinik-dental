import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../branches/data/branch_model.dart';
import '../../branches/data/branch_repository.dart';
import '../../doctors/data/doctor_model.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../patient/application/session_controller.dart';
import '../../patient/presentation/add_patient_sheet.dart';
import '../../treatments/data/treatment_repository.dart';
import '../data/reservation_repository.dart';

class BookingFlowPage extends ConsumerStatefulWidget {
  const BookingFlowPage({super.key});

  @override
  ConsumerState<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends ConsumerState<BookingFlowPage> {
  int _currentStep = 0;

  // Selected values
  Branch? _selectedBranch;
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  final Set<String> _selectedTreatmentIds = {};
  final _complaintController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _currentStep == 0 || _currentStep == 3 ? AppColors.primary : Colors.white,
        foregroundColor: _currentStep == 0 || _currentStep == 3 ? Colors.white : AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          _stepTitle(_currentStep),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1PilihKlinik(),
                  _buildStep2PilihPasien(),
                  _buildStep3PilihTanggalDokter(),
                  _buildStep4PilihPerawatan(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Pilih Klinik';
      case 1:
        return 'Pilih Pasien';
      case 2:
        return 'Pilih Tanggal & Dokter';
      case 3:
        return 'Pilih Rencana Perawatan';
      default:
        return 'Reservasi';
    }
  }

  // --- STEP 1: PILIH KLINIK ---
  Widget _buildStep1PilihKlinik() {
    final branchesAsync = ref.watch(branchListProvider);

    return Column(
      children: [
        // Top banner header
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih klinik',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Terdapat cabang Nina Dental Care di Kab. Bandung!',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // City selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.pink),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Bandung & Sekitarnya', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: branchesAsync.when(
            data: (branches) {
              if (branches.isEmpty) {
                return const Center(child: Text('Belum ada cabang klinik terdaftar.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: branches.length,
                itemBuilder: (context, i) {
                  final branch = branches[i];
                  final isSelected = _selectedBranch?.id == branch.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBranch = branch;
                        _currentStep = 1;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.pink : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Clinic image placeholder
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            child: Container(
                              height: 110,
                              width: double.infinity,
                              color: Colors.green.shade100,
                              child: const Icon(Icons.location_city_rounded, size: 48, color: AppColors.primary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  branch.address,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedBranch = branch;
                                        _currentStep = 1;
                                      });
                                    },
                                    child: const Text('Reservasi', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SkeletonBranchGrid(),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: PILIH PASIEN ---
  Widget _buildStep2PilihPasien() {
    final session = ref.watch(sessionControllerProvider).value;

    if (session == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Anda belum terdaftar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Daftar terlebih dahulu untuk membuat reservasi.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push('/register'),
              child: const Text('Daftar Sekarang'),
            ),
          ],
        ),
      );
    }

    final fullName = session.fullName;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Untuk siapa reservasi ini? Pilih pasien di bawah ini.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          const Text('Profil Pasien Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          // Main Patient Radio Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked, color: AppColors.pink, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'No RM: Belum Terhubung.',
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Profil Dipilih',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.pink),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => AddPatientSheet.show(context),
            icon: const Icon(Icons.add, color: AppColors.pink),
            label: const Text('+ Tambah Pasien', style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Lanjut Ke Pilih Dokter'),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: PILIH TANGGAL & DOKTER ---
  Widget _buildStep3PilihTanggalDokter() {
    final doctorsAsync = ref.watch(doctorListProvider);

    return Column(
      children: [
        // Date Strip
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      side: const BorderSide(color: AppColors.pink),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    icon: const Icon(Icons.calendar_month, size: 16, color: AppColors.pink),
                    label: const Text('Buka Kalender', style: TextStyle(fontSize: 12, color: AppColors.pink)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final dayDate = DateTime.now().add(Duration(days: i));
                    final isSelected = DateUtils.isSameDay(dayDate, _selectedDate);
                    final dayName = DateFormat('EEE', 'id_ID').format(dayDate);
                    final dayNum = DateFormat('dd').format(dayDate);
                    final monthName = DateFormat('MMM', 'id_ID').format(dayDate);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = dayDate),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.pink : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppColors.pink : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayNum,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              monthName,
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // Doctor Search & List
        Expanded(
          child: doctorsAsync.when(
            data: (doctors) {
              if (doctors.isEmpty) {
                return const Center(child: Text('Belum ada dokter praktek pada cabang ini.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: doctors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final doctor = doctors[i];
                  final isSelected = _selectedDoctor?.id == doctor.id;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDoctor = doctor),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.pink : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: doctor.photoUrl != null
                                      ? CachedNetworkImage(imageUrl: doctor.photoUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 32, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      doctor.specialization ?? 'Dokter Gigi Umum',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text('4.96', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Wrap(
                            spacing: 6,
                            children: [
                              Chip(label: Text('Senin', style: TextStyle(fontSize: 10))),
                              Chip(label: Text('Selasa', style: TextStyle(fontSize: 10))),
                              Chip(label: Text('Rabu', style: TextStyle(fontSize: 10))),
                              Chip(label: Text('Kamis', style: TextStyle(fontSize: 10))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => SkeletonList(itemBuilder: (_, _) => const SkeletonDoctorCard(), itemCount: 4),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
        if (_selectedDoctor != null) _buildTimeSlotPicker(),
        // Bottom CTA
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedDoctor == null || _selectedTimeSlot == null
                  ? null
                  : () {
                      setState(() => _currentStep = 3);
                    },
              child: const Text('Pilih Rencana Perawatan'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotPicker() {
    final detailAsync = ref.watch(doctorDetailProvider(_selectedDoctor!.id));
    return detailAsync.when(
      data: (detail) {
        final slots = _availableSlots(detail);
        if (slots.isEmpty) {
          if (_selectedTimeSlot != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedTimeSlot = null);
            });
          }
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Dokter tidak praktik pada tanggal ini. Silakan pilih tanggal lain.',
              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          );
        }
        if (_selectedTimeSlot == null || !slots.contains(_selectedTimeSlot)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedTimeSlot = slots.first);
          });
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Jam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((s) {
                  final selected = s == _selectedTimeSlot;
                  return ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    selectedColor: AppColors.pink.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _selectedTimeSlot = s),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Hourly slots derived from the doctor's real weekly schedule for the
  /// currently selected branch + date, instead of a fixed placeholder time.
  List<String> _availableSlots(DoctorDetail detail) {
    final beDayOfWeek = _selectedDate.weekday % 7; // Dart Mon=1..Sun=7 -> backend Sun=0..Sat=6
    final todaysSchedules = detail.schedules.where(
      (s) => s.dayOfWeek == beDayOfWeek && (_selectedBranch == null || s.branchId == _selectedBranch!.id),
    );

    final slots = <String>[];
    for (final s in todaysSchedules) {
      final startParts = s.startTime.split(':');
      final endParts = s.endTime.split(':');
      var totalMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      while (totalMinutes < endMinutes) {
        final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
        final m = (totalMinutes % 60).toString().padLeft(2, '0');
        slots.add('$h:$m');
        totalMinutes += 60;
      }
    }
    return slots;
  }

  // --- STEP 4: PILIH RENCANA PERAWATAN ---
  Widget _buildStep4PilihPerawatan() {
    final treatmentsAsync = ref.watch(treatmentListProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate);

    return Column(
      children: [
        // Summary Header
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedBranch?.name ?? 'Nina Dental Care',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedTimeSlot, $dateStr',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDoctor?.fullName ?? 'Dokter Gigi',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Search & List Treatments
        Expanded(
          child: treatmentsAsync.when(
            data: (treatments) {
              if (treatments.isEmpty) {
                return const Center(child: Text('Belum ada data perawatan.'));
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final item in treatments) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedTreatmentIds.contains(item.id),
                            activeColor: AppColors.pink,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedTreatmentIds.add(item.id);
                                } else {
                                  _selectedTreatmentIds.remove(item.id);
                                }
                              });
                            },
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: Colors.green.shade100,
                              child: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  currency.format(item.price),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _complaintController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: '(Opsional) Tuliskan keluhan...',
                    ),
                  ),
                ],
              );
            },
            loading: () => SkeletonList(itemBuilder: (_, _) => const SkeletonTreatmentCard(), itemCount: 4),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
        // Submit Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitReservation,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Buat Reservasi'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReservation() async {
    if (_selectedBranch == null || _selectedDoctor == null || _selectedTimeSlot == null) return;

    final session = ref.read(sessionControllerProvider).value;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan daftar/masuk akun terlebih dahulu sebelum membuat reservasi.')),
      );
      context.push('/register');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(reservationRepositoryProvider);

      final timeParts = _selectedTimeSlot!.split(':');
      final scheduledAtDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final created = await repo.createReservation(
        CreateReservationInput(
          patientId: session.patientId,
          branchId: _selectedBranch!.id,
          staffId: _selectedDoctor!.id,
          scheduledAt: scheduledAtDate,
          complaintNote: _complaintController.text.trim().isEmpty ? null : _complaintController.text.trim(),
          treatmentIds: _selectedTreatmentIds.toList(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservasi berhasil dibuat! Silakan pilih metode pembayaran.')),
        );
        context.push('/payment/checkout?reservationId=${created.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat reservasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
