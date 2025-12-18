/// Represents a download source for a game tool
enum SourceType {
  googlePlay,
  apk,
  github,
  website,
}

class ToolDownloadSource {
  final String name;
  final String url;
  final SourceType type;

  const ToolDownloadSource({
    required this.name,
    required this.url,
    required this.type,
  });

  /// Get icon for source type
  String get iconName {
    switch (type) {
      case SourceType.googlePlay:
        return 'play_store';
      case SourceType.apk:
        return 'android';
      case SourceType.github:
        return 'code';
      case SourceType.website:
        return 'language';
    }
  }
}

/// Represents a game tool that can run games from specific engines
class GameTool {
  final String id;
  final String name;
  final String description;
  final String packageName;
  final String? iconUrl;
  final List<String> supportedEngines;
  final List<ToolDownloadSource> downloadSources;
  final bool isPlugin; // If true, requires parent tool (e.g., JoiPlay)
  final String? parentToolId; // Parent tool ID if this is a plugin

  const GameTool({
    required this.id,
    required this.name,
    required this.description,
    required this.packageName,
    this.iconUrl,
    required this.supportedEngines,
    required this.downloadSources,
    this.isPlugin = false,
    this.parentToolId,
  });

  /// Check if this tool supports a specific engine
  bool supportsEngine(String engine) {
    final normalizedEngine = engine.toLowerCase().trim();
    return supportedEngines.any((e) => 
      e.toLowerCase().contains(normalizedEngine) ||
      normalizedEngine.contains(e.toLowerCase())
    );
  }
}
