import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../data/content_models.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artikel')),
      body: ListView(
        children: [
          if (article.coverImageUrl != null)
            CachedNetworkImage(imageUrl: article.coverImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.categoryName != null)
                  Chip(label: Text(article.categoryName!), visualDensity: VisualDensity.compact),
                const SizedBox(height: 10),
                Text(article.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (article.publishedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(formatDate(article.publishedAt!), style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 16),
                Text(article.body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
