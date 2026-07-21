import '../constants/game_tools_data.dart';
import '../models/game_tool.dart';

/// Catalog query service for available game tools
class GameToolsCatalog {
  GameToolsCatalog._();

  /// Get all available tools
  static List<GameTool> getAllTools() => GameToolsData.tools;

  /// Get all main tools (excluding plugins)
  static List<GameTool> getMainTools() => GameToolsData.mainTools;

  /// Get plugins for a parent tool
  static List<GameTool> getPluginsFor(String parentToolId) =>
      GameToolsData.getPluginsFor(parentToolId);

  /// Get tool by ID
  static GameTool? getToolById(String id) => GameToolsData.getToolById(id);

  /// Get all tools that support a specific engine
  static List<GameTool> getToolsForEngine(String engine) =>
      GameToolsData.getToolsForEngine(engine);
}
