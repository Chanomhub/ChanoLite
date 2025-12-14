import 'package:flutter/material.dart';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/widgets/app_network_image.dart';
import 'package:chanolite/utils/image_url_helper.dart';

/// A card widget for displaying an article in a list or grid.
class ArticleCard extends StatelessWidget {
  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.width = 180,
    this.height = 240,
    this.showFavorites = true,
  });

  final Article article;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool showFavorites;

  String? get _imageUrl {
    return ImageUrlHelper.getFirstValid([
      article.coverImage,
      article.mainImage,
      article.backgroundImage,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppNetworkImage(
                    imageUrl: _imageUrl,
                    width: 360,
                    height: 203,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (showFavorites)
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${article.favoritesCount}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
