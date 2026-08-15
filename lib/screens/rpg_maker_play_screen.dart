import 'dart:async';
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
  InAppWebViewController? _webViewController;
  bool _isServerReady = false;
  String _serverUrl = '';

  // In-Game Gamepad & Cheat states
  bool _showGamepad = true;
  int _currentSpeed = 1;
  Timer? _keyHoldTimer;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start local game server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _keyHoldTimer?.cancel();
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

  /// Simulate a keyboard keypress event inside WebView
  void _simulateKey(int keyCode) {
    if (_webViewController == null) return;
    final js = '''
      (function() {
        var eventDown = new KeyboardEvent('keydown', { keyCode: $keyCode, which: $keyCode, bubbles: true, cancelable: true });
        var eventUp = new KeyboardEvent('keyup', { keyCode: $keyCode, which: $keyCode, bubbles: true, cancelable: true });
        document.dispatchEvent(eventDown);
        window.dispatchEvent(eventDown);
        setTimeout(function() {
          document.dispatchEvent(eventUp);
          window.dispatchEvent(eventUp);
        }, 60);
      })();
    ''';
    _webViewController!.evaluateJavascript(source: js);
  }

  /// Start continuous keypress hold for D-pad direction movement
  void _startKeyHold(int keyCode) {
    _simulateKey(keyCode);
    _keyHoldTimer?.cancel();
    _keyHoldTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _simulateKey(keyCode);
    });
  }

  /// Stop keypress hold
  void _stopKeyHold() {
    _keyHoldTimer?.cancel();
    _keyHoldTimer = null;
  }

  /// Execute built-in MinHub-style RPG Maker Cheats
  Future<void> _executeCheat(String cheatType) async {
    if (_webViewController == null) return;
    String js = '';

    switch (cheatType) {
      case 'gold':
        js = r'''
          (function() {
            if (typeof $gameParty !== 'undefined') {
              $gameParty.gainGold(99999);
              return "💰 Added 99,999 Gold!";
            }
            return "RPG Maker Party object not ready.";
          })();
        ''';
        break;

      case 'heal':
        js = r'''
          (function() {
            if (typeof $gameParty !== 'undefined') {
              $gameParty.members().forEach(function(m) { m.recoverAll(); });
              return "❤️ Fully restored HP & MP for all party members!";
            }
            return "Party not ready.";
          })();
        ''';
        break;

      case 'noclip':
        js = r'''
          (function() {
            if (typeof $gamePlayer !== 'undefined') {
              $gamePlayer._through = !$gamePlayer._through;
              return "🚶 No-Clip (Passable) set to " + $gamePlayer._through;
            }
            return "Player object not ready.";
          })();
        ''';
        break;

      case 'enemy1hp':
        js = r'''
          (function() {
            if (typeof $gameTroop !== 'undefined' && $gameTroop.inBattle()) {
              $gameTroop.members().forEach(function(e) { if (e.isAlive()) e._hp = 1; });
              return "⚡ Enemy HP set to 1!";
            }
            return "Not currently in battle.";
          })();
        ''';
        break;

      case 'killall':
        js = r'''
          (function() {
            if (typeof $gameTroop !== 'undefined' && $gameTroop.inBattle()) {
              $gameTroop.members().forEach(function(e) { if (e.isAlive()) e.die(); });
              return "💥 Defeated all enemies!";
            }
            return "Not currently in battle.";
          })();
        ''';
        break;

      case 'noencounters':
        js = r'''
          (function() {
            if (typeof $gamePlayer !== 'undefined') {
              $gamePlayer._encounterCount = 999999;
              return "🛡️ Random encounters disabled!";
            }
            return "Player not ready.";
          })();
        ''';
        break;

      case 'maxstats':
        js = r'''
          (function() {
            if (typeof $gameParty !== 'undefined') {
              $gameParty.members().forEach(function(a) {
                if (a._paramPlus) {
                  a._paramPlus[0] += 5000; // Max HP
                  a._paramPlus[1] += 5000; // Max MP
                  a._paramPlus[2] += 500;  // ATK
                  a._paramPlus[3] += 500;  // DEF
                  a.recoverAll();
                }
              });
              return "💪 Maxed out party stats (+HP/MP/ATK/DEF)!";
            }
            return "Party not ready.";
          })();
        ''';
        break;
    }

    if (js.isNotEmpty) {
      final res = await _webViewController!.evaluateJavascript(source: js);
      if (mounted && res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.toString().replaceAll('"', '')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Toggle game speed hack multiplier (1x, 2x, 4x, 8x)
  void _toggleSpeed() {
    int nextSpeed = _currentSpeed == 1
        ? 2
        : _currentSpeed == 2
            ? 4
            : _currentSpeed == 4
                ? 8
                : 1;

    setState(() {
      _currentSpeed = nextSpeed;
    });

    if (_webViewController == null) return;
    final js = '''
      (function() {
        window._chanoSpeed = $nextSpeed;
        if (!window._chanoSpeedPatched && typeof SceneManager !== 'undefined') {
          window._chanoSpeedPatched = true;
          var origUpdate = SceneManager.updateMain;
          SceneManager.updateMain = function() {
            var count = window._chanoSpeed || 1;
            for (var i = 0; i < count; i++) {
              origUpdate.call(SceneManager);
            }
          };
        }
      })();
    ''';
    _webViewController!.evaluateJavascript(source: js);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏩ Game speed set to ${_currentSpeed}x'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Open Cheat Menu Bottom Sheet
  void _showCheatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.amber, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'ChanoLite In-Game Cheat Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildCheatButton(
                      icon: Icons.monetization_on,
                      label: '+99k Gold',
                      color: Colors.amber,
                      onTap: () {
                        Navigator.pop(context);
                        _executeCheat('gold');
                      },
                    ),
                    _buildCheatButton(
                      icon: Icons.favorite,
                      label: 'Full Heal All',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _executeCheat('heal');
                      },
                    ),
                    _buildCheatButton(
                      icon: Icons.directions_walk,
                      label: 'No-Clip (Wall Pass)',
                      color: Colors.cyanAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _executeCheat('noclip');
                      },
                    ),
                    _buildCheatButton(
                      icon: Icons.flash_on,
                      label: 'Enemies 1 HP',
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _executeCheat('enemy1hp');
                      },
                    ),
                    _buildCheatButton(
                      icon: Icons.dangerous,
                      label: 'Kill All Enemies',
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _executeCheat('killall');
                      },
                    ),
                    _buildCheatButton(
                      icon: Icons.shield,
                      label: 'No Encounters',
                      color: Colors.lightGreenAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _executeCheat('noencounters');
                      },
                    ),
                    _buildCheatButton(
                      icon: Icons.fitness_center,
                      label: 'Max Stats',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _executeCheat('maxstats');
                      },
                    ),
                    _buildCheatButton(
                      icon: Icons.speed,
                      label: 'Speed: ${_currentSpeed}x',
                      color: Colors.yellowAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _toggleSpeed();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheatButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[850],
        foregroundColor: color,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.4)),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      onPressed: onTap,
    );
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
                  // Main Game WebView
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
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print('[Game Console] ${consoleMessage.message}');
                    },
                    onLoadError: (controller, url, code, message) {
                      print('WebView error loading $url: [$code] $message');
                    },
                  ),

                  // Top Action Bar Overlays
                  Positioned(
                    top: 12,
                    left: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () {
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
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Exit'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        // Cheat Menu Button
                        CircleAvatar(
                          backgroundColor: Colors.amber.withOpacity(0.85),
                          child: IconButton(
                            icon: const Icon(Icons.bolt, color: Colors.black, size: 24),
                            onPressed: _showCheatMenu,
                            tooltip: 'Cheat Menu',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Gamepad Overlay Toggle
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: Icon(
                              _showGamepad ? Icons.gamepad : Icons.gamepad_outlined,
                              color: _showGamepad ? Colors.greenAccent : Colors.white70,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _showGamepad = !_showGamepad;
                              });
                            },
                            tooltip: 'Toggle Virtual Gamepad',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Speed Multiplier Button
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: Text(
                              '${_currentSpeed}x',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: _toggleSpeed,
                            tooltip: 'Toggle Game Speed',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Touch Virtual Gamepad Overlay
                  if (_showGamepad) ...[
                    // Left D-Pad Controls
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            // Up (Arrow / KeyCode 38)
                            Align(
                              alignment: Alignment.topCenter,
                              child: _buildDPadButton(
                                icon: Icons.arrow_drop_up,
                                keyCode: 38,
                              ),
                            ),
                            // Down (Arrow / KeyCode 40)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: _buildDPadButton(
                                icon: Icons.arrow_drop_down,
                                keyCode: 40,
                              ),
                            ),
                            // Left (Arrow / KeyCode 37)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _buildDPadButton(
                                icon: Icons.arrow_left,
                                keyCode: 37,
                              ),
                            ),
                            // Right (Arrow / KeyCode 39)
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildDPadButton(
                                icon: Icons.arrow_right,
                                keyCode: 39,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Action Buttons Controls
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Row(
                        children: [
                          // Shift / Run Button (KeyCode 16)
                          _buildActionButton(
                            label: 'SHIFT',
                            keyCode: 16,
                            color: Colors.blueAccent.withOpacity(0.6),
                          ),
                          const SizedBox(width: 10),
                          // ESC / Menu Button (KeyCode 27)
                          _buildActionButton(
                            label: 'ESC',
                            keyCode: 27,
                            color: Colors.redAccent.withOpacity(0.6),
                          ),
                          const SizedBox(width: 10),
                          // OK / Enter Button (KeyCode 13)
                          _buildActionButton(
                            label: 'OK',
                            keyCode: 13,
                            color: Colors.greenAccent.withOpacity(0.6),
                            size: 56,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDPadButton({
    required IconData icon,
    required int keyCode,
  }) {
    return GestureDetector(
      onTapDown: (_) => _startKeyHold(keyCode),
      onTapUp: (_) => _stopKeyHold(),
      onTapCancel: _stopKeyHold,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required int keyCode,
    required Color color,
    double size = 48,
  }) {
    return GestureDetector(
      onTapDown: (_) => _simulateKey(keyCode),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
