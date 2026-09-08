import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';

class RpgMakerServer {
  HttpServer? _server;
  String _gamePath;
  int _port = 0;
  final Map<String, String> _fileCache = {};

  RpgMakerServer(this._gamePath);

  int get port => _port;

  /// Start the local HTTP server and scan files for case-insensitive lookup cache
  Future<void> start() async {
    // 1. Scan game directory recursively to build case-insensitive file mapping
    await _buildFileCache();

    // 2. Start the HTTP server on loopback interface
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    print('RpgMakerServer: Server started on http://localhost:$_port');

    // 3. Listen to incoming requests
    _server!.listen(_handleRequest);
  }

  /// Stop the server
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _fileCache.clear();
      print('RpgMakerServer: Server stopped');
    }
  }

  /// Scan the game directory recursively to map lowercase paths to absolute file paths
  Future<void> _buildFileCache() async {
    _fileCache.clear();
    final gameDir = Directory(_gamePath);
    if (!await gameDir.exists()) return;

    final List<FileSystemEntity> entities = await gameDir.list(recursive: true).toList();
    for (final entity in entities) {
      if (entity is File) {
        // Calculate relative path from game directory root
        final relativePath = p.relative(entity.path, from: _gamePath);
        // Map lowercase relative path to actual file path
        final normalizedKey = relativePath.replaceAll('\\', '/').toLowerCase();
        _fileCache[normalizedKey] = entity.path;
      }
    }
    print('RpgMakerServer: Indexed ${_fileCache.length} files for case-insensitive lookup');
  }

  /// Handle incoming HTTP requests
  void _handleRequest(HttpRequest request) async {
    // Only allow GET requests
    if (request.method != 'GET') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
      return;
    }

    try {
      // Decode and clean up requested path
      String rawPath = Uri.decodeComponent(request.uri.path);
      if (rawPath.startsWith('/')) {
        rawPath = rawPath.substring(1);
      }
      
      // Default to index.html if request is empty
      if (rawPath.isEmpty) {
        rawPath = 'index.html';
      }

      final searchKey = rawPath.toLowerCase();
      String? actualFilePath = _fileCache[searchKey];

      // Asset extension fallback (handles MinHub-style audio/image casing & encryption extension fallback)
      if (actualFilePath == null) {
        if (searchKey.endsWith('.rpgmvo') || searchKey.endsWith('.m4a')) {
          final oggKey = searchKey.replaceAll(RegExp(r'\.(rpgmvo|m4a)$'), '.ogg');
          actualFilePath = _fileCache[oggKey];
        } else if (searchKey.endsWith('.rpgmvp')) {
          final pngKey = searchKey.replaceAll(RegExp(r'\.rpgmvp$'), '.png');
          actualFilePath = _fileCache[pngKey];
        }
      }

      if (actualFilePath != null) {
        final file = File(actualFilePath);
        if (await file.exists()) {
          final mimeType = lookupMimeType(actualFilePath) ?? 'application/octet-stream';
          final fileLength = await file.length();
          
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.parse(mimeType);
          request.response.headers.contentLength = fileLength;
          
          // Add caching and access control headers
          request.response.headers.add('Cache-Control', 'public, max-age=31536000, immutable');
          request.response.headers.add('Access-Control-Allow-Origin', '*');
          
          // Stream file content directly to response
          await file.openRead().pipe(request.response);
          return;
        }
      }

      // If not found in cache or file does not exist, return 404
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('File not found: $rawPath');
      await request.response.close();
    } catch (e) {
      print('RpgMakerServer: Error handling request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }
}
