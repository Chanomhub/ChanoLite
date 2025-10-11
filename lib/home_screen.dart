import 'package:chanolite/services/api/article_service.dart';
import 'package:flutter/material.dart';
import 'models/article_model.dart';
import 'article_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArticleService _articleService = ArticleService();
  List<Article> _articles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _articleService.getArticles(limit: 20);
      setState(() {
        _articles = response.articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToSearch({
    String? query,
    String? tag,
    String? category,
    String? platform,
    String? engine,
    String? status,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          initialQuery: query,
          initialTag: tag,
          initialCategory: category,
          initialPlatform: platform,
          initialEngine: engine,
          initialStatus: status,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChanoLite - Home'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadArticles),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArticles,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return const Center(child: Text('No articles found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickSearchSection(),
            _buildFeaturedSection(),
            _buildAllArticlesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchSection() {
    final topTags = _topItems((article) => article.tagList);
    final topPlatforms = _topItems((article) => article.platformList);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search articles'),
              subtitle: const Text('Find guides, downloads, and updates'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _navigateToSearch(),
            ),
          ),
          if (topTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Popular tags', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topTags
                  .map(
                    (tag) => ActionChip(
                      label: Text('#$tag'),
                      onPressed: () => _navigateToSearch(tag: tag),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (topPlatforms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Platforms', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topPlatforms
                  .map(
                    (platform) => ActionChip(
                      label: Text(platform),
                      onPressed: () => _navigateToSearch(platform: platform),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _topItems(
    List<String> Function(Article) extractor, {
    int limit = 6,
  }) {
    final Map<String, int> counts = {};
    final Map<String, String> displayLabels = {};

    for (final article in _articles) {
      final values = extractor(article);
      for (final value in values) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) continue;
        final key = trimmed.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
        displayLabels[key] = trimmed;
      }
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        final countCompare = counts[b]!.compareTo(counts[a]!);
        if (countCompare != 0) {
          return countCompare;
        }
        return displayLabels[a]!.compareTo(displayLabels[b]!);
      });

    return sortedKeys.take(limit).map((key) => displayLabels[key]!).toList();
  }

  Widget _buildFeaturedSection() {
    final featuredArticles = _articles.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Featured',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredArticles.length,
            itemBuilder: (context, index) {
              final article = featuredArticles[index];
              final imageUrl =
                  article.coverImage ??
                  article.mainImage ??
                  article.backgroundImage;
              return SizedBox(
                width: 150,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArticleDetailScreen(article: article),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.article),
                                    );
                                  },
                                )
                              : Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.article),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'All Articles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _articles.length,
          itemBuilder: (context, index) {
            final article = _articles[index];
            final imageUrl =
                article.coverImage ??
                article.mainImage ??
                article.backgroundImage;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.article),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.article),
                      ),
                title: Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 14),
                        const SizedBox(width: 4),
                        Text('${article.favoritesCount} favorites'),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArticleDetailScreen(article: article),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
