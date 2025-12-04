import 'package:chanolite/game_library_screen.dart';
import 'package:chanolite/theme/locale_notifier.dart';

import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'package:chanolite/utils/url_helper.dart';
import 'package:chanolite/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chanolite/services/cache_service.dart';
import 'package:chanolite/services/local_notification_service.dart';
import 'models/article_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

import 'package:chanolite/models/download.dart';

class ArticleDetailScreen extends StatefulWidget {
  final int articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late Article _article;
  bool _isLoading = true;
  String? _error;
  String? _lastLanguageCode;

 // Removed downloads from here, but wait, I need to remove it from the string literal below.

  // Actually, I will replace the whole string to be safe.
  static const String _detailArticleFields = r'''
    id
    slug
    sequentialCode
    title
    description
    body
    status
    ver
    coverImage
    backgroundImage
    images {
      url
    }
    author {
      name
      image
    }
    creators {
      name
    }
    categories {
      name
    }
    tags {
      name
    }
    platforms {
      name
    }
    engine {
      name
    }
    favoritesCount
    createdAt
    updatedAt
  ''';

  @override
  void initState() {
    super.initState();
    _article = Article.idOnly(widget.articleId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Provider.of<LocaleNotifier>(context).locale;

    if (_lastLanguageCode != locale.languageCode) {
      _lastLanguageCode = locale.languageCode;
      _loadArticle(locale);
    }
  }

  Future<void> _loadArticle(Locale language) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final cacheService = Provider.of<CacheService>(context, listen: false);
    final service = Provider.of<ArticleService>(context, listen: false);
    final cacheKey = 'article_${widget.articleId}_${language.languageCode}';

    // Try cache first
    final cachedArticle = cacheService.get(cacheKey);
    if (cachedArticle != null && cachedArticle is Article) {
      if (mounted) {
        setState(() {
          _article = cachedArticle;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      Article fetchedArticle;
      fetchedArticle = await service.getArticleById(widget.articleId, language: language, returnFields: _detailArticleFields);

      // Fetch downloads separately
      final downloads = await service.getDownloads(widget.articleId);
      
      fetchedArticle = fetchedArticle.copyWith(downloads: downloads);

      if (mounted) {
        setState(() {
          _article = fetchedArticle;
          _isLoading = false;
        });
        cacheService.set(cacheKey, _article);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load article: $_error', textAlign: TextAlign.center),
              ),
              ElevatedButton(
                onPressed: () {
                  final locale = Provider.of<LocaleNotifier>(context, listen: false).locale;
                  _loadArticle(locale);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _article.body.isEmpty) {
       return const Scaffold(
         body: Center(child: CircularProgressIndicator()),
       );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, _article),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, _article),
                  const SizedBox(height: 24),
                  _buildTags(context, _article),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Description'),
                  const SizedBox(height: 12),
                  Text(
                    _article.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildDownloads(context),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Content'),
                  const SizedBox(height: 12),
                  _buildHtmlContent(context, _article),
                  const SizedBox(height: 32),
                  if (_article.images.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Gallery'),
                    const SizedBox(height: 16),
                    _buildGallery(context, _article),
                    const SizedBox(height: 32),
                  ],
                  _buildInfoTable(context, _article),
                  const SizedBox(height: 80), // Bottom padding for FAB or just spacing
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Article article) {
    return SliverAppBar(
      expandedHeight: 320.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            article.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: article.coverImage!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.article, size: 80, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
            // Gradient Overlay for text readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.6, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Article article) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: article.author?.image != null ? CachedNetworkImageProvider(article.author!.image!) : null,
              child: article.author?.image == null
                  ? Text(article.author?.name.isNotEmpty == true ? article.author!.name[0].toUpperCase() : '?',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer))
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.author?.name ?? 'Unknown Author',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  article.createdAt != null ? DateFormat.yMMMd().format(article.createdAt!) : 'N/A',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  article.favorited ? Icons.favorite : Icons.favorite_border,
                  color: article.favorited ? Colors.red : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  // TODO: Implement favorite functionality
                },
                tooltip: 'Favorite',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              article.favoritesCount.toString(),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTags(BuildContext context, Article article) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        ...article.tagList.map((tag) => _buildChip(context, tag, isTag: true)),
        ...article.categoryList.map((cat) => _buildChip(context, cat, color: Colors.blue)),
        ...article.platformList.map((plat) => _buildChip(context, plat, color: Colors.green)),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, {bool isTag = false, Color? color}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color chipColor = color ?? colorScheme.secondary;
    if (isTag) {
       chipColor = colorScheme.tertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDownloads(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _article.downloads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_article.downloads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No downloads available.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Downloads'),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _article.downloads.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final link = _article.downloads[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleDownload(context, link),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.cloud_download_outlined, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              link.url,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHtmlContent(BuildContext context, Article article) {
    return Html(
      data: article.body,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize.medium,
          lineHeight: LineHeight.em(1.6),
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
        "p": Style(
          margin: Margins.only(bottom: 16),
        ),
        "img": Style(
          width: Width(100, Unit.percent),
          height: Height.auto(),
          margin: Margins.symmetric(vertical: 16),
        ),
      },
    );
  }

  Widget _buildGallery(BuildContext context, Article article) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: article.images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: article.images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTable(BuildContext context, Article article) {
    final theme = Theme.of(context);
    
    Widget buildRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Details'),
          const SizedBox(height: 8),
          buildRow('ID', article.id.toString()),
          const Divider(height: 1),
          buildRow('Code', article.sequentialCode ?? 'N/A'),
          const Divider(height: 1),
          buildRow('Engine', article.engine ?? 'N/A'),
          const Divider(height: 1),
          buildRow('Version', article.ver ?? 'N/A'),
          const Divider(height: 1),
          buildRow('Status', article.status ?? 'N/A'),
          const Divider(height: 1),
          buildRow('Updated', DateFormat.yMMMd().format(article.updatedAt)),
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, dynamic link) async {
    final permissionStatus = await PermissionHelper.requestStoragePermission();
    if (!permissionStatus) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to download files.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final downloadManager = Provider.of<DownloadManager>(context, listen: false);
    final authToken = Provider.of<AuthManager>(context, listen: false).activeAccount?.token;
    final article = _article;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Open Link'),
          content: const Text('Choose how you want to open this link.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('External Browser'),
              onPressed: () {
                Navigator.of(context).pop();
                _openLink(context, link.url, downloadManager, authToken, article, useExternalBrowser: true);
              },
            ),
            FilledButton(
              child: const Text('In-App Browser'),
              onPressed: () {
                Navigator.of(context).pop();
                _openLink(context, link.url, downloadManager, authToken, article, useExternalBrowser: false);
              },
            ),
          ],
        );
      },
    );
  }

  void _openLink(
    BuildContext context,
    String url,
    DownloadManager downloadManager,
    String? authToken,
    Article article, {
    required bool useExternalBrowser,
  }) {
    InAppBrowserHelper.openUrl(
      url,
      downloadManager: downloadManager,
      authToken: authToken,
      useExternalBrowser: useExternalBrowser,
      onDownloadStart: (downloadStartRequest) async {
        await LocalNotificationService.showNotification(
          title: 'Download Detected',
          body: 'A download has been detected and will begin shortly.',
        );

        final fileName = InAppBrowserHelper.extractFilename(downloadStartRequest.contentDisposition) ??
            InAppBrowserHelper.getFilenameFromUrl(downloadStartRequest.url) ??
            downloadStartRequest.suggestedFilename;
        
        if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Confirm Download'),
                  content: Text('Do you want to download this file?\n\n$fileName'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                    FilledButton(
                      child: const Text('Download'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        downloadManager.startDownload(
                          downloadStartRequest.url.toString(),
                          suggestedFilename: fileName,
                          authToken: authToken,
                          imageUrl: article.coverImage ?? article.mainImage,
                          version: article.ver?.toString(),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Download started!'),
                            action: SnackBarAction(
                              label: 'LIBRARY',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const GameLibraryScreen()),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
        }
      },
    );
  }
}
