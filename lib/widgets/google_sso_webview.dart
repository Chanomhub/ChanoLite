import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class GoogleSsoWebview extends StatefulWidget {
  final String loginUrl;
  final String callbackUrl;

  const GoogleSsoWebview({
    super.key,
    required this.loginUrl,
    required this.callbackUrl,
  });

  @override
  State<GoogleSsoWebview> createState() => _GoogleSsoWebviewState();
}

class _GoogleSsoWebviewState extends State<GoogleSsoWebview> {
  InAppWebViewController? webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.loginUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
              userAgent: "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36",
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
              _checkRedirect(url);
            },
            onLoadStop: (controller, url) async {
              setState(() {
                _isLoading = false;
              });
              _checkRedirect(url);
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _checkRedirect(WebUri? url) async {
    if (url == null) return;
    
    // Check if redirect matches callback URL
    if (url.toString().startsWith(widget.callbackUrl)) {
      final cookieManager = CookieManager.instance();
      // Retrieve cookies set on the API domain
      final apiUri = WebUri(widget.loginUrl);
      final cookies = await cookieManager.getCookies(url: apiUri);
      
      // Construct cookie header string
      final cookieHeader = cookies.map((c) => '${c.name}=${c.value}').join('; ');
      
      if (mounted) {
        Navigator.of(context).pop(cookieHeader);
      }
    }
  }
}
