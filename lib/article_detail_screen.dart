import 'package:chanolite/game_library_screen.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'package:chanolite/utils/url_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chanolite/services/cache_service.dart';
import 'models/article_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Article? _article;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('Initializing ArticleDetailScreen for article: ${widget.article.slug}');
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    final cache = Provider.of<CacheService>(context, listen: false);
    final cacheKey = 'article_${widget.article.id}';

    // Try to get from cache first
    final cachedArticle = cache.get(cacheKey);
    if (cachedArticle != null && cachedArticle is Article) {
      if (mounted) {
        setState(() {
          _article = cachedArticle;
          _isLoading = false;
        });
        print('Article loaded from CACHE: ${_article?.title}');
      }
      return;
    }

    // If not in cache, fetch from network
    try {
      Article article;
      if (widget.article.slug != null && widget.article.slug!.isNotEmpty) {
        article = await ArticleService().getArticleBySlug(widget.article.slug);
      } else {
        article = await ArticleService().getArticleById(widget.article.id);
      }

      if (mounted) {
        // Save to cache before setting state
        cache.set(cacheKey, article);
        
        setState(() {
          _article = article;
          _isLoading = false;
        });
        print('Article loaded from NETWORK: ${_article?.title}');
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        print('Error loading article: $e');
        print(stackTrace);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    print('Building ArticleDetailScreen: isLoading: $_isLoading, error: $_error, article: ${_article?.title}');
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.article.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.article.title)),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_article == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.article.title)),
        body: const Center(child: Text('Article not found.')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorInfo(context),
                  const SizedBox(height: 16),
                  _buildTags(context),
                  const SizedBox(height: 16),
                  Text('Description', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_article!.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  _buildDownloadSection(context),
                  const SizedBox(height: 16),
                  Text('Body', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Html(data: _article!.body ?? ''),
                  const SizedBox(height: 16),
                  _buildImageGallery(context),
                  const SizedBox(height: 16),
                  _buildInfoTable(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_article!.title, style: const TextStyle(fontSize: 16.0)),
        background: _article!.coverImage != null
            ? Image.network(
                _article!.coverImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
              )
            : const Icon(Icons.image),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: _article!.author.image != null ? NetworkImage(_article!.author.image!) : null,
          onBackgroundImageError: (exception, stackTrace) {},
          child: _article!.author.image == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_article!.author.name, style: Theme.of(context).textTheme.titleMedium),
            Text(DateFormat.yMMMd().format(_article!.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: Icon(_article!.favorited ? Icons.favorite : Icons.favorite_border),
          color: _article!.favorited ? Colors.red : null,
          onPressed: () { /* Handle favorite */ },
        ),
        Text(_article!.favoritesCount.toString()),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
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
        ..._article!.tagList.map((tag) => Chip(label: Text(tag))),
        ..._article!.categoryList.map((category) => buildChip(category, getColor(category))),
        ..._article!.platformList.map((platform) => buildChip(platform, getColor(platform))),
      ],
    );
  }

  Widget _buildDownloadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Downloads', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_article!.downloads.isEmpty)
          const Center(child: Text('No download links available.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _article!.downloads.length,
            itemBuilder: (context, index) {
              final link = _article!.downloads[index];
              return Card(
                child: ListTile(
                  title: Text(link.name),
                  subtitle: Text(link.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      final downloadManager = Provider.of<DownloadManager>(context, listen: false);
                      final authToken = Provider.of<AuthManager>(context, listen: false).activeAccount?.token;
                      InAppBrowserHelper.openUrl(
                        link.url,
                        downloadManager: downloadManager,
                        authToken: authToken,
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
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _article!.images.length,
        itemBuilder: (context, index) {
          return Card(
            child: Image.network(
              _article!.images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTable(BuildContext context) {
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
            _buildInfoTableRow('ID', _article!.id.toString()),
            _buildInfoTableRow('Sequential Code', _article!.sequentialCode ?? 'N/A'),
            _buildInfoTableRow('Engine', _article!.engine ?? 'N/A'),
            _buildInfoTableRow('Version', _article!.version?.toString() ?? 'N/A'),
            _buildInfoTableRow('Status', _article!.status ?? 'N/A'),
            _buildInfoTableRow('Created At', DateFormat.yMMMd().format(_article!.createdAt)),
            _buildInfoTableRow('Updated At', DateFormat.yMMMd().format(_article!.updatedAt)),
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
