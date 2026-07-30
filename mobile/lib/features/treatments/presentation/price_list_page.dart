import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../data/treatment_model.dart';
import '../data/treatment_repository.dart';

class PriceListPage extends ConsumerStatefulWidget {
  const PriceListPage({super.key});

  @override
  ConsumerState<PriceListPage> createState() => _PriceListPageState();
}

class _PriceListPageState extends ConsumerState<PriceListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treatments = ref.watch(treatmentListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Harga')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cari perawatan...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(treatmentListProvider.future),
              child: AsyncValueView<List<Treatment>>(
                value: treatments,
                onRetry: () => ref.invalidate(treatmentListProvider),
                data: (list) {
                  final filtered = _query.isEmpty
                      ? list
                      : list.where((t) => t.name.toLowerCase().contains(_query) || t.categoryName.toLowerCase().contains(_query)).toList();
                  if (filtered.isEmpty) {
                    return const EmptyState(icon: Icons.search_off, message: 'Tidak ada perawatan yang cocok.');
                  }
                  final grouped = <String, List<Treatment>>{};
                  for (final t in filtered) {
                    grouped.putIfAbsent(t.categoryName, () => []).add(t);
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final entry in grouped.entries) ...[
                        SectionHeader(title: entry.key),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < entry.value.length; i++) ...[
                                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                                ListTile(
                                  title: Text(entry.value[i].name),
                                  subtitle: Text('${entry.value[i].durationMinutes} menit'),
                                  trailing: Text(
                                    formatIDR(entry.value[i].price),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reservations/new'),
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Reservasi'),
      ),
    );
  }
}
