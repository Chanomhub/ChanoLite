import 'package:applovin_max/applovin_max.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'article_detail_screen.dart';
import 'models/article_model.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArticleService _articleService = ArticleService();
  final PageController _heroPageController = PageController(
    viewportFraction: 0.86,
    keepPage: true,
  );
  static const String _sdkKey = 'YOUR_APPLOVIN_SDK_KEY';
  static const String _bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';
  List<Article> _articles = [];
  List<Article> _heroArticles = [];
  List<_CuratedSection> _curatedSections = [];
  List<String> _topTags = [];
  List<String> _topPlatforms = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAppLovin();
    _loadArticles();
  }

  @override
  void dispose() {
    try {
      AppLovinMAX.destroyBanner(_bannerAdUnitId);
    } on MissingPluginException catch (error) {
      debugPrint('AppLovin destroy failed: $error');
    }
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _initializeAppLovin() async {
    try {
      final configuration = await AppLovinMAX.initialize(_sdkKey);
      if (configuration == null) {
        return;
      }
      AppLovinMAX.loadBanner(_bannerAdUnitId);
    } on MissingPluginException catch (error) {
      debugPrint('AppLovin initialize failed: $error');
    } catch (error, stackTrace) {
      debugPrint('AppLovin initialize error: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final attempts = <Future<void> Function()>[
          () => _fetchAndApplyArticles(limit: 60, status: 'PUBLISHED'),
          () => _fetchAndApplyArticles(limit: 60),
          () => _fetchAndApplyArticles(limit: 40),
    ];

    Object? lastError;

    for (final attempt in attempts) {
      try {
        await attempt();
        return;
      } catch (error, stackTrace) {
        lastError = error;
        debugPrint('Home load attempt failed: $error');
        debugPrint('$stackTrace');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _error = lastError?.toString() ?? 'Failed to load articles.';
      _isLoading = false;
    });
  }

  Future<void> _fetchAndApplyArticles({
    required int limit,
    String? status,
  }) async {
    final response = await _articleService.getArticles(
      limit: limit,
      status: status,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _articles = response.articles;
      _prepareHomeContent();
      _isLoading = false;
      _error = null;
    });
  }

  void _prepareHomeContent() {
    if (_articles.isEmpty) {
      _heroArticles = [];
      _curatedSections = [];
      _topTags = [];
      _topPlatforms = [];
      return;
    }

    final published = List<Article>.from(_articles);

    final popular = List<Article>.from(published)
      ..sort((a, b) => b.favoritesCount.compareTo(a.favoritesCount));
    final recent = List<Article>.from(published)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    _heroArticles = popular.take(6).toList();

    final curated = <_CuratedSection>[
      _CuratedSection(
        title: 'Recently updated',
        subtitle: 'Fresh patches and new content',
        articles: recent.take(12).toList(),
        onSeeAll: () => _navigateToSearch(status: 'PUBLISHED'),
      ),
      _CuratedSection(
        title: 'Popular picks',
        subtitle: 'Fan favourites right now',
        articles: popular.take(15).toList(),
        onSeeAll: () => _navigateToSearch(status: 'PUBLISHED'),
      ),
    ];

    final tagHighlights = _topItems((article) => article.tagList, limit: 4);
    _topTags = tagHighlights;
    for (final tag in tagHighlights) {
      final tagged = published
          .where(
            (article) => article.tagList.any(
              (value) => value.toLowerCase() == tag.toLowerCase(),
        ),
      )
          .take(12)
          .toList();
      if (tagged.length < 3) continue;
      curated.add(
        _CuratedSection(
          title: '#$tag spotlight',
          subtitle: 'Hand-picked for $tag fans',
          articles: tagged,
          onSeeAll: () => _navigateToSearch(tag: tag),
        ),
      );
    }

    final platformHighlights = _topItems(
          (article) => article.platformList,
      limit: 3,
    );
    _topPlatforms = platformHighlights;
    for (final platform in platformHighlights) {
      final platformArticles = published
          .where(
            (article) => article.platformList.any(
              (value) => value.toLowerCase() == platform.toLowerCase(),
        ),
      )
          .take(12)
          .toList();
      if (platformArticles.length < 3) continue;
      curated.add(
        _CuratedSection(
          title: '$platform essentials',
          subtitle: 'Optimised for $platform players',
          articles: platformArticles,
          onSeeAll: () => _navigateToSearch(platform: platform),
        ),
      );
    }

    _curatedSections = curated
        .where((section) => section.articles.isNotEmpty)
        .toList();
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

  void _openArticle(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Flexible(child: Text('ChanoLite - Home')),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎃',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Halloween 2025',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '👻',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AuthManager>(
            builder: (context, auth, _) {
              final theme = Theme.of(context);
              final user = auth.activeAccount;
              final hasAccounts = auth.accounts.isNotEmpty;

              Widget avatar;
              if (user != null && (user.image ?? '').isNotEmpty) {
                avatar = CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(user.image!),
                  backgroundColor: theme.colorScheme.primaryContainer,
                );
              } else {
                final label = user?.username.isNotEmpty == true
                    ? user!.username[0].toUpperCase()
                    : '+';
                avatar = CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(label),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      if (hasAccounts) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const AccountSwitcherSheet(),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: avatar,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null && !_isLoading) {
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

    if (_articles.isEmpty && !_isLoading) {
      return const Center(child: Text('No articles found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: CustomScrollView(
        physics: _isLoading
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Skeletonizer(
              enabled: _isLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchCard(),
                  _buildTopFilters(),
                  if (_heroArticles.isNotEmpty || _isLoading)
                    _buildHeroCarousel(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            ...List.filled(2, _CuratedSection.dummy()).map(
                  (section) => SliverToBoxAdapter(
                child: Skeletonizer(
                  enabled: true,
                  child: _buildHorizontalSection(section),
                ),
              ),
            )
          else
            ..._curatedSections.map(
                  (section) => SliverToBoxAdapter(
                child: _buildHorizontalSection(section),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _navigateToSearch,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Search the library',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find new builds, engines, or creators',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopFilters() {
    final tags = _isLoading ? List.filled(4, '        ') : _topTags;
    final platforms = _isLoading ? List.filled(3, '          ') : _topPlatforms;

    if (tags.isEmpty && platforms.isEmpty) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    for (final tag in tags) {
      chips.add(
        ActionChip(
          label: Text('#$tag'),
          onPressed: _isLoading ? null : () => _navigateToSearch(tag: tag),
        ),
      );
    }

    for (final platform in platforms) {
      chips.add(
        ActionChip(
          label: Text(platform),
          onPressed: _isLoading ? null : () => _navigateToSearch(platform: platform),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemBuilder: (context, index) => chips[index],
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: chips.length,
      ),
    );
  }

  Widget _buildHeroCarousel() {
    final articles = _isLoading ? List.filled(3, Article.dummy()) : _heroArticles;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 250,
        child: PageView.builder(
          controller: _heroPageController,
          physics: _isLoading ? const NeverScrollableScrollPhysics() : null,
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return RepaintBoundary(
              child: _buildHeroCard(article),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(Article article) {
    final imageUrl = article.coverImage ??
        article.mainImage ??
        article.backgroundImage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: _isLoading ? null : () => _openArticle(article),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  cacheHeight: 450,
                  filterQuality: FilterQuality.medium,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildImageFallback();
                  },
                  errorBuilder: (context, error, stack) => _buildImageFallback(),
                )
              else
                _buildImageFallback(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(_CuratedSection section) {
    if (section.articles.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (section.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            section.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (section.onSeeAll != null)
                  TextButton(
                    onPressed: _isLoading ? null : section.onSeeAll,
                    child: const Text('See all'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final article = section.articles[index];
                return RepaintBoundary(
                  child: _buildStoreCard(article),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: section.articles.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Article article) {
    final imageUrl = article.coverImage ??
        article.mainImage ??
        article.backgroundImage;

    return SizedBox(
      width: 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isLoading ? null : () => _openArticle(article),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
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
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 360,
                    cacheHeight: 203,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImageFallback();
                    },
                    errorBuilder: (context, error, stack) =>
                        _buildImageFallback(),
                  )
                      : _buildImageFallback(),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.favorite, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${article.favoritesCount}',
                            style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.article,
          color: Colors.black54,
          size: 48,
        ),
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
}

class _CuratedSection {
  const _CuratedSection({
    required this.title,
    required this.articles,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final List<Article> articles;
  final VoidCallback? onSeeAll;

  factory _CuratedSection.dummy() {
    return _CuratedSection(
      title: '                ',
      subtitle: '                    ',
      articles: List.filled(5, Article.dummy()),
    );
  }
}