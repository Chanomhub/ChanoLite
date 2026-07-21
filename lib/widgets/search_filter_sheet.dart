import 'package:flutter/material.dart';

class SearchFilterData {
  final String? tag;
  final String? category;
  final String? platform;
  final String? engine;
  final String? sequentialCode;
  final String? status;

  const SearchFilterData({
    this.tag,
    this.category,
    this.platform,
    this.engine,
    this.sequentialCode,
    this.status,
  });
}

class SearchFilterSheet extends StatefulWidget {
  final SearchFilterData initialFilters;

  const SearchFilterSheet({
    super.key,
    required this.initialFilters,
  });

  static Future<SearchFilterData?> show(
    BuildContext context, {
    required SearchFilterData initialFilters,
  }) {
    return showModalBottomSheet<SearchFilterData>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: SearchFilterSheet(initialFilters: initialFilters),
        ),
      ),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late final TextEditingController _filterTagController;
  late final TextEditingController _filterCategoryController;
  late final TextEditingController _filterPlatformController;
  late final TextEditingController _filterEngineController;
  late final TextEditingController _filterSequentialCodeController;
  late String _statusValue;

  static const List<String> _statusOptions = [
    'PUBLISHED',
    'DRAFT',
    'ARCHIVED',
    'SUSPENDED',
  ];

  static const List<String> _platformSuggestions = [
    'Windows',
    'Android',
    'Mac',
    'Linux',
  ];

  static const List<String> _engineSuggestions = [
    'RENPY',
    'RPG_MAKER',
    'UNITY',
    'UNREAL',
  ];

  @override
  void initState() {
    super.initState();
    _filterTagController = TextEditingController(text: widget.initialFilters.tag ?? '');
    _filterCategoryController = TextEditingController(text: widget.initialFilters.category ?? '');
    _filterPlatformController = TextEditingController(text: widget.initialFilters.platform ?? '');
    _filterEngineController = TextEditingController(text: widget.initialFilters.engine ?? '');
    _filterSequentialCodeController = TextEditingController(text: widget.initialFilters.sequentialCode ?? '');
    _statusValue = widget.initialFilters.status ?? '';
  }

  @override
  void dispose() {
    _filterTagController.dispose();
    _filterCategoryController.dispose();
    _filterPlatformController.dispose();
    _filterEngineController.dispose();
    _filterSequentialCodeController.dispose();
    super.dispose();
  }

  String? _normalize(String value) {
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

  void _clearAll() {
    setState(() {
      _filterTagController.clear();
      _filterCategoryController.clear();
      _filterPlatformController.clear();
      _filterEngineController.clear();
      _filterSequentialCodeController.clear();
      _statusValue = '';
    });
  }

  void _apply() {
    FocusScope.of(context).unfocus();
    final result = SearchFilterData(
      tag: _normalize(_filterTagController.text),
      category: _normalize(_filterCategoryController.text),
      platform: _normalize(_filterPlatformController.text),
      engine: _normalize(_filterEngineController.text),
      sequentialCode: _normalize(_filterSequentialCodeController.text),
      status: _statusValue.isEmpty ? null : _statusValue,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            setState(() {
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
            setState(() {
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
          value: _statusValue,
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
            setState(() {
              _statusValue = value ?? '';
            });
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear all'),
            ),
            ElevatedButton(
              onPressed: _apply,
              child: const Text('Apply'),
            ),
          ],
        ),
      ],
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
