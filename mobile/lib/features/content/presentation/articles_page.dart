import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_header.dart';
import '../data/content_models.dart';
import '../data/content_repository.dart';

class ArticlesPage extends ConsumerWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articleListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Artikel & Tips')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(articleListProvider.future),
        child: AsyncValueView<List<Article>>(
          value: articles,
          onRetry: () => ref.invalidate(articleListProvider),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(icon: Icons.article_outlined, message: 'Belum ada artikel.');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final article = list[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/articles/${article.id}', extra: article),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: article.coverImageUrl != null
                              ? CachedNetworkImage(imageUrl: article.coverImageUrl!, fit: BoxFit.cover)
                              : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                if (article.categoryName != null) Text(article.categoryName!, style: Theme.of(context).textTheme.bodySmall),
                                if (article.publishedAt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(formatDate(article.publishedAt!), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
