import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/managers/download_manager.dart';
import 'package:chanolite/models/download_model.dart';
import 'package:chanolite/services/api/download_service.dart';
import 'package:chanolite/utils/url_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'models/article_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final DownloadService _downloadService = DownloadService();
  List<DownloadLinkDTO> _downloadLinks = [];
  bool _isLoadingLinks = true;
  String? _linksError;

  @override
  void initState() {
    super.initState();
    _loadDownloadLinks();
  }

  Future<void> _loadDownloadLinks() async {
    try {
      final links = await _downloadService.getDownloadLinks(widget.article.id);
      setState(() {
        _downloadLinks = links;
        _isLoadingLinks = false;
      });
    } catch (e) {
      setState(() {
        _linksError = e.toString();
        _isLoadingLinks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(widget.article.description, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  _buildDownloadSection(context),
                  const SizedBox(height: 16),
                  Text('Body', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Html(data: widget.article.body),
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
        title: Text(widget.article.title, style: const TextStyle(fontSize: 16.0)),
        background: Image.network(
          widget.article.coverImage ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
        ),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.article.author.image ?? ''),
          onBackgroundImageError: (exception, stackTrace) {},
          child: widget.article.author.image == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.article.author.username, style: Theme.of(context).textTheme.titleMedium),
            Text(DateFormat.yMMMd().format(widget.article.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: Icon(widget.article.favorited ? Icons.favorite : Icons.favorite_border),
          color: widget.article.favorited ? Colors.red : null,
          onPressed: () { /* Handle favorite */ },
        ),
        Text(widget.article.favoritesCount.toString()),
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        ...widget.article.tagList.map((tag) => Chip(label: Text(tag))),
        ...widget.article.categoryList.map((category) => Chip(label: Text(category), backgroundColor: Colors.blue.shade100)),
        ...widget.article.platformList.map((platform) => Chip(label: Text(platform), backgroundColor: Colors.green.shade100)),
      ],
    );
  }

  Widget _buildDownloadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Downloads', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_isLoadingLinks)
          const Center(child: CircularProgressIndicator())
        else if (_linksError != null)
          Center(child: Text('Error loading links: $_linksError'))
        else if (_downloadLinks.isEmpty)
          const Center(child: Text('No download links available.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _downloadLinks.length,
            itemBuilder: (context, index) {
              final link = _downloadLinks[index];
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
                              // This assumes MainScreen is managing the BottomNavBar index.
                              // A more robust solution might use a global key or a different state management approach for navigation.
                              // For now, this is a simple way to request a tab change.
                              // Note: This won't work if the user navigates away from MainScreen.
                              // A better way is to have a dedicated navigator for each tab.
                              // But for this case, we will just pop until we reach the root.
                              Navigator.of(context).popUntil((route) => route.isFirst);
                              // Then we need to tell the MainScreen to switch tabs. This is the tricky part.
                              // A simple approach is to not do anything and let the user tap the library tab.
                              // The SnackBar is just a notification.
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
        itemCount: widget.article.images.length,
        itemBuilder: (context, index) {
          return Card(
            child: Image.network(
              widget.article.images[index],
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
            _buildInfoTableRow('ID', widget.article.id.toString()),
            _buildInfoTableRow('Sequential Code', widget.article.sequentialCode ?? 'N/A'),
            _buildInfoTableRow('Engine', widget.article.engine ?? 'N/A'),
            _buildInfoTableRow('Version', widget.article.version?.toString() ?? 'N/A'),
            _buildInfoTableRow('Status', widget.article.status),
            _buildInfoTableRow('Created At', DateFormat.yMMMd().format(widget.article.createdAt)),
            _buildInfoTableRow('Updated At', DateFormat.yMMMd().format(widget.article.updatedAt)),
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