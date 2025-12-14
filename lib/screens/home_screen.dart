import 'package:chanolite/utils/image_url_helper.dart';

import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:chanolite/services/api/article_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:async';

import 'package:chanolite/screens/article_detail_screen.dart';
import 'package:chanolite/models/article_model.dart';
import 'package:chanolite/screens/search_screen.dart';
import 'package:chanolite/widgets/home/section_header.dart';
import 'package:chanolite/widgets/home/app_card.dart';
import 'package:chanolite/widgets/home/top_rated_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ArticleService _articleService = ArticleService();

  List<Article> _articles = [];
  List<Article> _unreleasedApps = [];
  List<Article> _gamesInDevelopment = [];
  List<Article> _topRatedApps = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // In a real scenario, we would fetch different lists based on status
      // modifying the query params for separate calls.
      // For now, we fetch a batch and distribute them to mock the design.
      await _fetchAndApplyArticles(limit: 60);

    } catch (error) {
       debugPrint('Home load attempt failed: $error');
       if(mounted) {
         setState(() {
           _error = error.toString();
           _isLoading = false;
         });
       }
    }
  }

  static const String _homeArticleFields = r'''
    id
    title
    description
    slug
    coverImage
    mainImage
    backgroundImage
    favoritesCount
    updatedAt
    tags {
      name
    }
    platforms {
      name
    }
  ''';

  Future<void> _fetchAndApplyArticles({
    required int limit,
    String? status,
  }) async {
    final response = await _articleService.getArticles(
      limit: limit,
      status: status,
      returnFields: _homeArticleFields,
    );

    if (!mounted) return;

    setState(() {
      _articles = response.articles;
      _prepareHomeContent();
      _isLoading = false;
      _error = null;
    });
  }

  void _prepareHomeContent() {
    if (_articles.isEmpty) {
      _unreleasedApps = [];
      _gamesInDevelopment = [];
      _topRatedApps = [];
      return;
    }

    final published = List<Article>.from(_articles);
    
    // Mocking the distribution
    _unreleasedApps = published.take(10).toList();
    _gamesInDevelopment = published.skip(10).take(10).toList();
    
    final popular = List<Article>.from(published)
      ..sort((a, b) => b.favoritesCount.compareTo(a.favoritesCount));
    _topRatedApps = popular.take(10).toList();
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
        builder: (context) => ArticleDetailScreen(articleId: article.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Flexible(child: Text('ChanoLite')),
            const SizedBox(width: 12),
          ],
        ),
        actions: [
          Consumer<AuthManager>(
            builder: (context, auth, _) {
              final theme = Theme.of(context);
              final user = auth.activeAccount;
              final hasAccounts = auth.accounts.isNotEmpty;

              Widget avatar;
              if (user != null && (user.image?.isNotEmpty ?? false)) {
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
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Error: $_error',
                textAlign: TextAlign.center,
              ),
            ),
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
                   _buildFilterBar(),
                   const SizedBox(height: 10),
                   _buildSection(
                     title: 'Unreleased Apps',
                     articles: _unreleasedApps,
                     onMore: () => _navigateToSearch(status: 'PENDING_REVIEW'), // Mocking status
                   ),
                   _buildSection(
                     title: 'Games in Development',
                     articles: _gamesInDevelopment,
                     onMore: () => _navigateToSearch(status: 'DRAFT'), // Mocking status
                   ),
                   _buildTopRatedSection(),
                ],
              ),
            ),
          ),
           const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
     return SingleChildScrollView(
       scrollDirection: Axis.horizontal,
       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
       child: Row(
         children: [
           _buildFilterChip('Top charts', isActive: true),
           const SizedBox(width: 8),
           _buildFilterChip('Children'),
           const SizedBox(width: 8),
           _buildFilterChip('Premium'),
           const SizedBox(width: 8),
           _buildFilterChip('Categories'),
           const SizedBox(width: 8),
           _buildFilterChip('Editors\' Choice'),
         ],
       ),
     );
  }

  Widget _buildFilterChip(String label, {bool isActive = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : theme.cardColor, // Light green for active
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF1B5E20) : theme.textTheme.bodyMedium?.color, // Dark green text
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


  Widget _buildSection({
    required String title,
    required List<Article> articles,
    VoidCallback? onMore,
  }) {
    if (articles.isEmpty && !_isLoading) return const SizedBox.shrink();
    
    final displayArticles = _isLoading ? List.filled(5, Article.dummy()) : articles;

    return Column(
      children: [
        SectionHeader(title: title, onMoreTap: onMore),
        SizedBox(
          height: 180, // Height for AppCard
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayArticles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 0), // Spacing handled in AppCard margin
            itemBuilder: (context, index) {
              final article = displayArticles[index];
              return AppCard(
                imageUrl: _getValidImageUrl(article),
                title: article.title,
                subtitle: article.tagList.isNotEmpty ? article.tagList.first : 'Unknown Genre',
                onTap: () => _isLoading ? null : _openArticle(article),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopRatedSection() {
     if (_topRatedApps.isEmpty && !_isLoading) return const SizedBox.shrink();
     
     final displayArticles = _isLoading ? List.filled(5, Article.dummy()) : _topRatedApps;

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Padding(
           padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
           child: Text(
             'Top Rated',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
           ),
         ),
         _buildTopRatedGroup(displayArticles),
       ],
     );
  }

  Widget _buildTopRatedGroup(List<Article> articles) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return TopRatedItem(
          rank: index + 1,
          imageUrl: _getValidImageUrl(article),
          title: article.title,
          subtitle: article.tagList.join(' • '),
          rating: 4.0 + (index % 10) / 10.0, // Mock rating
          onTap: () => _isLoading ? null : _openArticle(article),
        );
      },
    );
  }

  String _getValidImageUrl(Article article) {
     return ImageUrlHelper.getFirstValid([
       article.coverImage,
       article.mainImage,
       article.backgroundImage,
     ]) ?? '';
  }
}