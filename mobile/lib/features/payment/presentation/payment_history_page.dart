import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../patient/application/session_controller.dart';
import '../data/payment_model.dart';
import '../data/payment_repository.dart';

class PaymentHistoryPage extends ConsumerWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: session == null
          ? _NoProfileState(onRegister: () => context.push('/register'))
          : Consumer(
              builder: (context, ref, _) {
                final payments = ref.watch(myPaymentsProvider(session.patientId));
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myPaymentsProvider(session.patientId).future),
                  child: AsyncValueView<List<Payment>>(
                    value: payments,
                    onRetry: () => ref.invalidate(myPaymentsProvider(session.patientId)),
                    data: (list) {
                      if (list.isEmpty) {
                        return const EmptyState(icon: Icons.receipt_long_outlined, message: 'Belum ada riwayat pembayaran.');
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _PaymentTile(payment: list[i]),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final Payment payment;

  Color _statusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (payment.status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return colorScheme.tertiary;
      case 'expired':
      case 'failed':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _statusColor(context).withValues(alpha: 0.15),
          child: Icon(Icons.receipt_outlined, color: _statusColor(context)),
        ),
        title: Text(formatIDR(payment.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${payment.branchName} · ${formatDateTime(payment.createdAt)}'),
        trailing: Chip(
          label: Text(paymentStatusLabel(payment.status), style: const TextStyle(fontSize: 11)),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _NoProfileState extends StatelessWidget {
  const _NoProfileState({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Lengkapi profil untuk melihat riwayat pembayaran Anda.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRegister, child: const Text('Lengkapi Profil')),
          ],
        ),
      ),
    );
  }
}
