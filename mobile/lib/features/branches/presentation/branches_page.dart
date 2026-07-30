import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../data/branch_model.dart';
import '../data/branch_repository.dart';

class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cabang Kami')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(branchListProvider.future),
        child: AsyncValueView<List<Branch>>(
          value: branches,
          onRetry: () => ref.invalidate(branchListProvider),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(icon: Icons.storefront_outlined, message: 'Belum ada data cabang.');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _BranchCard(branch: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch});

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.local_hospital_rounded, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(branch.city, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                if (!branch.isActive)
                  const Chip(label: Text('Tutup Sementara'), visualDensity: VisualDensity.compact),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(icon: Icons.place_outlined, text: branch.address),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.schedule_outlined, text: 'Buka setiap hari ${branch.opensAt} – ${branch.closesAt}'),
            if (branch.phone != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.call_outlined, text: branch.phone!),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/reservations/new?branchId=${branch.id}'),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Reservasi di Cabang Ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
