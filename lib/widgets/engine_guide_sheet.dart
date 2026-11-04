import 'package:flutter/material.dart';

import 'package:chanolite/constants/engine_tool_guide.dart';

/// "Which player runs this game?" — shown when a user downloads a game so
/// they know what to install before trying to play it.
class EngineGuideSheet extends StatelessWidget {
  final EngineToolGuide guide;
  final String gameTitle;

  const EngineGuideSheet({
    super.key,
    required this.guide,
    required this.gameTitle,
  });

  /// Shows the guide for [engine]; no-op when the engine is unknown —
  /// don't nag users with a guess.
  static Future<void> showForEngine(
    BuildContext context, {
    required String gameTitle,
    String? engine,
  }) {
    final guide = EngineToolGuide.forEngine(engine);
    if (guide == null) return Future.value();
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EngineGuideSheet(guide: guide, gameTitle: gameTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Playing ${guide.title} games',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Players that can run "$gameTitle":',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: guide.entries.length,
                itemBuilder: (context, index) {
                  final entry = guide.entries[index];
                  final tool = EngineToolGuide.toolById(entry.toolId);
                  final name = tool?.name ?? entry.toolId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(name, style: theme.textTheme.titleSmall),
                    subtitle: Text(entry.detail),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
