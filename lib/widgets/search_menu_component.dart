import 'package:flutter/material.dart';

class SearchMenuComponent extends StatelessWidget {
  const SearchMenuComponent({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClearQuery,
    required this.onFilterPressed,
    this.onSubmitted,
    this.hasActiveFilters = false,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearQuery;
  final VoidCallback onFilterPressed;
  final ValueChanged<String>? onSubmitted;
  final bool hasActiveFilters;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search articles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                suffixIcon: _buildSuffixIcon(),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 12),
          _FilterButton(
            hasActiveFilters: hasActiveFilters,
            onPressed: onFilterPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: controller.text.isNotEmpty
          ? IconButton(
              key: const ValueKey('clear'),
              icon: const Icon(Icons.clear),
              onPressed: onClearQuery,
            )
          : isLoading
          ? const Padding(
              key: ValueKey('loading'),
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const SizedBox(key: ValueKey('empty')),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.hasActiveFilters,
    required this.onPressed,
  });

  final bool hasActiveFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          shape: const CircleBorder(),
          child: IconButton(icon: const Icon(Icons.tune), onPressed: onPressed),
        ),
        if (hasActiveFilters)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
