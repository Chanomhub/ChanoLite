import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chanolite/utils/image_url_helper.dart';

/// A reusable cached network image widget with consistent placeholder and error handling.
/// Supports both full URLs and relative paths (e.g., '/abc123.jpg').
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String? imageUrl;
  final int? width;
  final int? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final fallback = _buildFallback(context);
    
    // Resolve relative URLs to full URLs
    final resolvedUrl = ImageUrlHelper.resolve(imageUrl);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return fallback;
    }

    Widget image = CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: fit,
      memCacheWidth: width,
      memCacheHeight: height,
      placeholder: (context, url) => placeholder ?? fallback,
      errorWidget: (context, url, error) => errorWidget ?? fallback,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 48,
        ),
      ),
    );
  }
}
