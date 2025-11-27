import 'package:chanolite/game_library_screen.dart';
import 'package:chanolite/managers/article_detail_manager.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/utils/url_helper.dart';
import 'package:chanolite/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chanolite/services/cache_service.dart';
import 'package:chanolite/services/local_notification_service.dart';
import 'models/article_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ArticleDetailManager(
        repository: Provider.of<ArticleRepository>(context, listen: false),
        cacheService: Provider.of<CacheService>(context, listen: false),
      )..loadArticle(article),
      child: const _ArticleDetailContent(),
    );
  }
}

class _ArticleDetailContent extends StatelessWidget {
  const _ArticleDetailContent();

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<ArticleDetailManager>(context);
    final article = manager.article;

    // If for some reason article is null (shouldn't happen given the structure), show loading
    if (article == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, article),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorInfo(context, article),
                  const SizedBox(height: 16),
                  _buildTags(context, article),
                  const SizedBox(height: 16),
                  Text('Description', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(article.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  _buildDownloadSection(context, manager),
                  const SizedBox(height: 16),
                  Text('Body', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Html(data: article.body),
                  const SizedBox(height: 16),
                  _buildImageGallery(context, article),
                  const SizedBox(height: 16),
                  _buildInfoTable(context, article),
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
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(article.title, style: const TextStyle(fontSize: 16.0)),
        background: article.coverImage != null
            ? CachedNetworkImage(
                imageUrl: article.coverImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => const Icon(Icons.image),
              )
            : const Icon(Icons.image),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context, Article article) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: article.author.image != null ? CachedNetworkImageProvider(article.author.image!) : null,
          onBackgroundImageError: (exception, stackTrace) {},
          child: article.author.image == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.author.name, style: Theme.of(context).textTheme.titleMedium),
            Text(DateFormat.yMMMd().format(article.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: Icon(article.favorited ? Icons.favorite : Icons.favorite_border),
          color: article.favorited ? Colors.red : null,
          onPressed: () { /* Handle favorite */ },
        ),
        Text(article.favoritesCount.toString()),
      ],
    );
  }

  Widget _buildTags(BuildContext context, Article article) {
    final theme = Theme.of(context);
    Color getColor(String text) {
      // Simple hash to get a color from a predefined list
      final colors = [
        Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple,
        Colors.teal, Colors.pink, Colors.indigo, Colors.cyan, Colors.brown,
      ];
      return colors[text.hashCode % colors.length];
    }

    Widget buildChip(String label, Color color) {
      final isDark = theme.brightness == Brightness.dark;
      final backgroundColor = isDark ? color.withOpacity(0.3) : color.withOpacity(0.15);
      final labelColor = isDark ? color.withOpacity(0.9) : color;

      return Chip(
        label: Text(label),
        backgroundColor: backgroundColor,
        labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w500),
        side: BorderSide.none,
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        ...article.tagList.map((tag) => Chip(label: Text(tag))),
        ...article.categoryList.map((category) => buildChip(category, getColor(category))),
        ...article.platformList.map((platform) => buildChip(platform, getColor(platform))),
      ],
    );
  }

  Widget _buildDownloadSection(BuildContext context, ArticleDetailManager manager) {
    final article = manager.article!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Downloads', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (manager.isLoading && article.downloads.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (manager.error != null && article.downloads.isEmpty)
           Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Failed to load downloads: ${manager.error}', style: const TextStyle(color: Colors.red)),
          )
        else if (article.downloads.isEmpty)
          const Center(child: Text('No download links available.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: article.downloads.length,
            itemBuilder: (context, index) {
              final link = article.downloads[index];
              return Card(
                child: ListTile(
                  title: Text(link.name),
                  subtitle: Text(link.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      final permissionStatus = await PermissionHelper.requestStoragePermission();

                      if (permissionStatus) {
                        final downloadManager = Provider.of<DownloadManager>(context, listen: false);
                        final authToken = Provider.of<AuthManager>(context, listen: false).activeAccount?.token;

                        InAppBrowserHelper.openUrl(
                          link.url,
                          downloadManager: downloadManager,
                          authToken: authToken,
                                                  onDownloadStart: (downloadStartRequest) async {
                                                    await LocalNotificationService.showNotification(
                                                      title: 'Download Detected',
                                                      body: 'A download has been detected and will begin shortly.',
                                                    );
                          
                                                    final fileName = InAppBrowserHelper.extractFilename(downloadStartRequest.contentDisposition) ??
                                                        InAppBrowserHelper.getFilenameFromUrl(downloadStartRequest.url) ??
                                                        downloadStartRequest.suggestedFilename;
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Confirm Download'),
                                  content: Text('Do you want to download this file?\n\n$fileName'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    TextButton(
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
                                              label: 'GO TO LIBRARY',
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => const GameLibraryScreen(),
                                                  ),
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
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Storage permission is required to download files.'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildImageGallery(BuildContext context, Article article) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: article.images.length,
        itemBuilder: (context, index) {
          return Card(
            child: CachedNetworkImage(
              imageUrl: article.images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[300]),
              errorWidget: (context, url, error) => const Icon(Icons.image),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTable(BuildContext context, Article article) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Information', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(),
          },
          children: [
            _buildInfoTableRow('ID', article.id.toString()),
            _buildInfoTableRow('Sequential Code', article.sequentialCode ?? 'N/A'),
            _buildInfoTableRow('Engine', article.engine ?? 'N/A'),
            _buildInfoTableRow('Version', article.ver ?? 'N/A'),
            _buildInfoTableRow('Status', article.status),
            _buildInfoTableRow('Created At', DateFormat.yMMMd().format(article.createdAt)),
            _buildInfoTableRow('Updated At', DateFormat.yMMMd().format(article.updatedAt)),
          ],
        ),
      ],
    );
  }

  TableRow _buildInfoTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value),
        ),
      ],
    );
  }
}
