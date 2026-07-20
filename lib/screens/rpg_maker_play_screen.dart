import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/rpg_maker_server.dart';

class RpgMakerPlayScreen extends StatefulWidget {
  final String gamePath;
  final String gameTitle;

  const RpgMakerPlayScreen({
    Key? key,
    required this.gamePath,
    required this.gameTitle,
  }) : super(key: key);

  @override
  State<RpgMakerPlayScreen> createState() => _RpgMakerPlayScreenState();
}

class _RpgMakerPlayScreenState extends State<RpgMakerPlayScreen> {
  RpgMakerServer? _server;
  bool _isServerReady = false;
  String _serverUrl = '';

  @override
  void initState() {
    super.initState();
    
    // Set screen to immersive fullscreen landscape mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _startLocalServer();
  }

  Future<void> _startLocalServer() async {
    try {
      _server = RpgMakerServer(widget.gamePath);
      await _server!.start();
      setState(() {
        _serverUrl = 'http://localhost:${_server!.port}/index.html';
        _isServerReady = true;
      });
    } catch (e) {
      print('RpgMakerPlayScreen: Error starting server: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start local game server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Restore system UI settings and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Stop local server
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isServerReady
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading local game server...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_serverUrl)),
                    initialSettings: InAppWebViewSettings(
                      useShouldOverrideUrlLoading: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      iframeAllowFullscreen: true,
                      supportZoom: false,
                      builtInZoomControls: false,
                      displayZoomControls: false,
                      databaseEnabled: true,
                      domStorageEnabled: true,
                      cacheEnabled: true,
                      cacheMode: CacheMode.LOAD_DEFAULT,
                      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                      hardwareAcceleration: false,
                    ),
                    onConsoleMessage: (controller, consoleMessage) {
                      print('[Game Console] ${consoleMessage.message}');
                    },
                    onLoadError: (controller, url, code, message) {
                      print('WebView error loading $url: [$code] $message');
                    },
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 30,
                      ),
                      onPressed: () {
                        // Confirm exit
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Exit Game'),
                            content: Text('Are you sure you want to exit ${widget.gameTitle}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context); // Exit play screen
                                },
                                child: const Text('Exit'),
                              ),
                            ],
                          ),
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
