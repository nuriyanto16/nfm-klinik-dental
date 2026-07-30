import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import 'skeleton_loader.dart';

/// Renders an [AsyncValue] with consistent loading (skeleton)/error/empty states across
/// the app instead of every page hand-rolling its own `.when(...)`.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
    this.padding = const EdgeInsets.all(24),
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () =>
          loading ??
          Padding(
            padding: padding,
            child: SkeletonList(
              itemBuilder: (_, _) => const SkeletonDoctorCard(),
              itemCount: 4,
              padding: EdgeInsets.zero,
            ),
          ),
      error: (err, stack) => Padding(
        padding: padding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(
                apiErrorMessage(err),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
