// lib/search_screen.dart
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chanolite/utils/image_url_helper.dart';
import 'package:chanolite/repositories/article_repository.dart';
import 'package:chanolite/services/cache_service.dart';
import 'package:chanolite/theme/app_theme.dart';
import 'package:chanolite/theme/theme_notifier.dart';
import 'package:chanolite/widgets/search_menu_component.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chanolite/screens/article_detail_screen.dart';
import 'package:chanolite/models/article_model.dart';

const _statusOptions = [
  'PUBLISHED',
  'PENDING_REVIEW',
  'DRAFT',
  'ARCHIVED',
  'NOT_APPROVED',
  'NEEDS_REVISION',
];

const _platformSuggestions = [
  'Windows',
  'Android',
  'iOS',
  'Mac',
  'Linux',
  'Web',
];

const _engineSuggestions = ['RENPY', 'UNITY', 'UNREAL', 'GODOT', 'RPG_MAKER'];

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialTag,
    this.initialCategory,
    this.initialPlatform,
    this.initialEngine,
    this.initialStatus,
  });

  final String? initialQuery;
  final String? initialTag;
  final String? initialCategory;
  final String? initialPlatform;
  final String? initialEngine;
  final String? initialStatus;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ArticleRepository _articleRepository;
  final CacheService _cacheService = CacheService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterTagController = TextEditingController();
  final TextEditingController _filterCategoryController =
      TextEditingController();
  final TextEditingController _filterPlatformController =
      TextEditingController();
  final TextEditingController _filterEngineController = TextEditingController();
  final TextEditingController _filterSequentialCodeController =
      TextEditingController();

  List<Article> _articles = [];
  int? _articlesCount;
  int _offset = 0;
  final int _limit = 20;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;

  String? _selectedTag;
  String? _selectedCategory;
  String? _selectedPlatform;
  String? _selectedEngine;
  String? _selectedStatus;
  String? _selectedSequentialCode;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _articleRepository = context.read<ArticleRepository>();
    _searchController.text = widget.initialQuery ?? '';
    _selectedTag = widget.initialTag;
    _selectedCategory = widget.initialCategory;
    _selectedPlatform = widget.initialPlatform;
    _selectedEngine = widget.initialEngine;
    _selectedStatus = widget.initialStatus;
    _scrollController.addListener(_onScroll);
    _loadArticles(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _filterTagController.dispose();
    _filterCategoryController.dispose();
    _filterPlatformController.dispose();
    _filterEngineController.dispose();
    _filterSequentialCodeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore) {
      _loadArticles();
    }
  }

  void _onQueryChanged(String value) {
    if (!mounted) {
      return;
    }
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1200), () {
      _loadArticles(reset: true);
    });
  }

  void _clearQuery() {
    if (_searchController.text.isEmpty) {
      return;
    }
    _searchController.clear();
    _onQueryChanged('');
  }

  Future<void> _loadArticles({bool reset = false}) async {
    if (reset) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = true;
        _error = null;
        _articles = [];
        _articlesCount = null;
        _offset = 0;
        _hasMore = false;
      });
    } else {
      if (!_hasMore || _isLoadingMore) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
    }

    final query = _normalizeFilter(_searchController.text);
    final cacheKey =
        'articles_search?q=$query&t=$_selectedTag&c=$_selectedCategory&p=$_selectedPlatform&e=$_selectedEngine&s=$_selectedStatus&sc=$_selectedSequentialCode&l=$_limit&o=$_offset';

    try {
      if (reset) {
        final cached = _cacheService.get(cacheKey);
        if (cached != null) {
          final response = ArticlesResponse.fromJson(cached);
          if (!mounted) {
            return;
          }
          setState(() {
            _articles = response.articles;
            _articlesCount = response.articlesCount;
            final fetched = response.articles.length;
            _offset = fetched;
            if (_articlesCount != null) {
              _hasMore = _articles.length < _articlesCount!;
            } else {
              _hasMore = fetched == _limit;
            }
            _isLoading = false;
          });
          return;
        }
      }

  const String _searchArticleFields = r'''
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

      final response = await _articleRepository.getArticles(
        limit: _limit,
        offset: _offset,
        query: query,
        tag: _selectedTag,
        category: _selectedCategory,
        platform: _selectedPlatform,
        engine: _selectedEngine,
        status: _selectedStatus,
        sequentialCode: _selectedSequentialCode,
        returnFields: _searchArticleFields,
      );

      if (reset && response.articles.isNotEmpty) {
        _cacheService.set(
          cacheKey,
          response.toJson(),
          duration: const Duration(minutes: 10),
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _articles = response.articles;
        } else {
          _articles = [..._articles, ...response.articles];
        }
        _articlesCount = response.articlesCount;
        final fetched = response.articles.length;
        _offset = reset ? fetched : _offset + fetched;
        if (_articlesCount != null) {
          _hasMore = _articles.length < _articlesCount!;
        } else {
          _hasMore = fetched == _limit;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  bool get _hasActiveFilters =>
      (_selectedTag?.isNotEmpty ?? false) ||
      (_selectedCategory?.isNotEmpty ?? false) ||
      (_selectedPlatform?.isNotEmpty ?? false) ||
      (_selectedEngine?.isNotEmpty ?? false) ||
      (_selectedStatus?.isNotEmpty ?? false) ||
      (_selectedSequentialCode?.isNotEmpty ?? false);

  String? _normalizeFilter(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatStatusLabel(String status) {
    return status
        .toLowerCase()
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  void _openFilters() async {
    _filterTagController.text = _selectedTag ?? '';
    _filterCategoryController.text = _selectedCategory ?? '';
    _filterPlatformController.text = _selectedPlatform ?? '';
    _filterEngineController.text = _selectedEngine ?? '';
    _filterSequentialCodeController.text = _selectedSequentialCode ?? '';
    String statusValue = _selectedStatus ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _filterTagController,
                      decoration: const InputDecoration(
                        labelText: 'Tag',
                        hintText: 'e.g. romance',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _filterCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g. update',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _filterPlatformController,
                      decoration: const InputDecoration(
                        labelText: 'Platform',
                        hintText: 'e.g. Windows',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SuggestionWrap(
                      title: 'Quick platforms',
                      suggestions: _platformSuggestions,
                      onSelected: (value) {
                        setModalState(() {
                          _filterPlatformController.text = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _filterEngineController,
                      decoration: const InputDecoration(
                        labelText: 'Engine',
                        hintText: 'e.g. RENPY',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SuggestionWrap(
                      title: 'Quick engines',
                      suggestions: _engineSuggestions,
                      onSelected: (value) {
                        setModalState(() {
                          _filterEngineController.text = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _filterSequentialCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Sequential Code',
                        hintText: 'e.g. HJ154',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: statusValue,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Any')),
                        ..._statusOptions.map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_formatStatusLabel(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          statusValue = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _filterTagController.clear();
                              _filterCategoryController.clear();
                              _filterPlatformController.clear();
                              _filterEngineController.clear();
                              _filterSequentialCodeController.clear();
                              statusValue = '';
                            });
                          },
                          child: const Text('Clear all'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).pop();
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _selectedTag = _normalizeFilter(
                                _filterTagController.text,
                              );
                              _selectedCategory = _normalizeFilter(
                                _filterCategoryController.text,
                              );
                              _selectedPlatform = _normalizeFilter(
                                _filterPlatformController.text,
                              );
                              _selectedEngine = _normalizeFilter(
                                _filterEngineController.text,
                              );
                              _selectedSequentialCode = _normalizeFilter(
                                _filterSequentialCodeController.text,
                              );
                              _selectedStatus = statusValue.isEmpty
                                  ? null
                                  : statusValue;
                            });
                            _loadArticles(reset: true);
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    if (_selectedTag?.isNotEmpty ?? false) {
      chips.add(
        _buildFilterChip('Tag: ${_selectedTag!}', () {
          setState(() {
            _selectedTag = null;
          });
          _loadArticles(reset: true);
        }),
      );
    }

    if (_selectedCategory?.isNotEmpty ?? false) {
      chips.add(
        _buildFilterChip('Category: ${_selectedCategory!}', () {
          setState(() {
            _selectedCategory = null;
          });
          _loadArticles(reset: true);
        }),
      );
    }

    if (_selectedPlatform?.isNotEmpty ?? false) {
      chips.add(
        _buildFilterChip('Platform: ${_selectedPlatform!}', () {
          setState(() {
            _selectedPlatform = null;
          });
          _loadArticles(reset: true);
        }),
      );
    }

    if (_selectedEngine?.isNotEmpty ?? false) {
      chips.add(
        _buildFilterChip('Engine: ${_selectedEngine!}', () {
          setState(() {
            _selectedEngine = null;
          });
          _loadArticles(reset: true);
        }),
      );
    }

    if (_selectedStatus?.isNotEmpty ?? false) {
      chips.add(
        _buildFilterChip('Status: ${_formatStatusLabel(_selectedStatus!)}', () {
          setState(() {
            _selectedStatus = null;
          });
          _loadArticles(reset: true);
        }),
      );
    }

    if (_selectedSequentialCode?.isNotEmpty ?? false) {
      chips.add(
        _buildFilterChip('Sequential Code: ${_selectedSequentialCode!}', () {
          setState(() {
            _selectedSequentialCode = null;
          });
          _loadArticles(reset: true);
        }),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Chip _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
    );
  }

  Widget _buildResultSummary() {
    if (_isLoading || _error != null || _articlesCount == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Found $_articlesCount result${_articlesCount == 1 ? '' : 's'}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChanoLite - Search'),
        actions: [
          Consumer<ThemeNotifier>(
            builder: (context, notifier, child) {
              final palette = notifier.currentPalette;
              if (palette == SeasonalPalette.standard) {
                return const SizedBox.shrink();
              }

              String text;
              String iconStart;
              String iconEnd;
              Color color;

              switch (palette) {
                case SeasonalPalette.christmas:
                  text = 'Christmas ${DateTime.now().year}';
                  iconStart = '🎄';
                  iconEnd = '🎅';
                  color = Colors.red.shade700;
                  break;
                case SeasonalPalette.spooky:
                  text = 'Halloween ${DateTime.now().year}';
                  iconStart = '🎃';
                  iconEnd = '👻';
                  color = Colors.orange.shade700;
                  break;
                case SeasonalPalette.summer:
                  text = 'Summer Vibes';
                  iconStart = '☀️';
                  iconEnd = '🏖️';
                  color = Colors.orangeAccent.shade400;
                  break;
                case SeasonalPalette.festive:
                  text = 'Festive Season';
                  iconStart = '🎉';
                  iconEnd = '✨';
                  color = Colors.purple.shade700;
                  break;
                default:
                  return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      iconStart,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      iconEnd,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SearchMenuComponent(
            controller: _searchController,
            onChanged: _onQueryChanged,
            onSubmitted: (_) => _loadArticles(reset: true),
            onClearQuery: _clearQuery,
            onFilterPressed: _openFilters,
            hasActiveFilters: _hasActiveFilters,
            isLoading: _isLoading,
          ),
          _buildActiveFilters(),
          _buildResultSummary(),
          Expanded(child: _buildBody()),
        ],
      ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Error: $_error', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadArticles(reset: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return const Center(child: Text('No articles match your search yet.'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadArticles(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _articles.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _articles.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final article = _articles[index];
          final imageUrl = ImageUrlHelper.getFirstValid([
            article.coverImage,
            article.mainImage,
            article.backgroundImage,
          ]);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        memCacheWidth: 120, // 2x for retina
                        memCacheHeight: 120,
                        maxWidthDiskCache: 200, // Limit disk cache size
                        maxHeightDiskCache: 200,
                        fadeInDuration: const Duration(milliseconds: 100), // Faster fade
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.article, color: Colors.black54),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.article, color: Colors.black54),
                        ),
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
                    builder: (context) => ArticleDetailScreen(articleId: article.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionWrap extends StatelessWidget {
  const _SuggestionWrap({
    required this.title,
    required this.suggestions,
    required this.onSelected,
  });

  final String title;
  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: suggestions
              .map(
                (item) => ActionChip(
                  label: Text(item),
                  onPressed: () => onSelected(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
