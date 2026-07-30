import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/storage/session_storage.dart';
import '../application/session_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: AsyncValueView<PatientSession?>(
        value: session,
        onRetry: () => ref.invalidate(sessionControllerProvider),
        data: (s) => s == null ? const _GuestView() : _ProfileView(session: s),
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Anda belum punya profil pasien',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi profil untuk bisa reservasi dan melihat riwayat kunjungan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/register'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Lengkapi Profil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.session});

  final PatientSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person, size: 36, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Text(session.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              if (session.phoneWa != null) Text(session.phoneWa!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Riwayat Reservasi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/reservations/history'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Riwayat Pembayaran'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/payments/history'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(sessionControllerProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Keluar dari Profil Ini'),
          style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error, side: BorderSide(color: colorScheme.error)),
        ),
      ],
    );
  }
}
