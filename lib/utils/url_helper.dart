import 'package:chanolite/managers/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppBrowserHelper extends InAppBrowser {
  final DownloadManager downloadManager;
  final String? authToken;
  final void Function(DownloadStartRequest) onDownloadStartCallback;


  InAppBrowserHelper({
    required this.downloadManager,
    this.authToken,
    required this.onDownloadStartCallback,
  });

  // A basic list of ad-related domains to block.
  static final List<String> _adBlockDomains = [
    '.doubleclick.net',
    // Add more domains as needed
  ];

  static final List<ContentBlocker> _contentBlockers = _adBlockDomains.map((domain) {
    return ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: '.*$domain.*'),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    );
  }).toList();

  static String? extractFilename(String? contentDisposition) {
    if (contentDisposition == null) {
      return null;
    }

    // Look for filename*=UTF-8''...
    final utf8FilenameRegex = RegExp(r"filename\*=UTF-8''(.+)");
    var match = utf8FilenameRegex.firstMatch(contentDisposition);
    if (match != null) {
      final encodedFilename = match.group(1);
      if (encodedFilename != null) {
        try {
          return Uri.decodeComponent(encodedFilename);
        } catch (e) {
          // Fallback to the next method if decoding fails
        }
      }
    }

    // Look for the older filename="..."
    final filenameRegex = RegExp(r'filename="([^"]+)"');
    match = filenameRegex.firstMatch(contentDisposition);
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  static String? getFilenameFromUrl(Uri url) {
    final path = url.path;
    if (path.isEmpty || path.endsWith('/')) {
      return null;
    }

    final segments = path.split('/');
    final lastSegment = segments.last;
    if (lastSegment.isEmpty) {
      return null;
    }

    try {
      return Uri.decodeComponent(lastSegment);
    } catch (e) {
      return lastSegment; // Return as is if decoding fails
    }
  }

  @override
  Future onBrowserCreated() async {}

  @override
  Future onLoadStart(url) async {}

  @override
  Future onLoadStop(url) async {}

  @override
  void onExit() {}

  static Future<void> openUrl(
      String url,
      {
        required DownloadManager downloadManager,
        String? authToken,
        required void Function(DownloadStartRequest) onDownloadStart,
        bool useExternalBrowser = false,
      }
      ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    if (useExternalBrowser) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
      return;
    }

    // ตั้งค่า cookie สำหรับ authentication
    if (authToken != null && authToken.isNotEmpty && uri.hasAuthority) {
      await CookieManager.instance().setCookie(
        url: WebUri('${uri.scheme}://${uri.host}'),
        name: 'token',
        value: authToken,
        path: '/',
        isHttpOnly: true,
        sameSite: HTTPCookieSameSitePolicy.LAX,
      );
    }

    final InAppBrowserHelper browser = InAppBrowserHelper(
      downloadManager: downloadManager,
      authToken: authToken,
      onDownloadStartCallback: onDownloadStart,
    );
    await browser.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(url)),
      options: InAppBrowserClassOptions(
        crossPlatform: InAppBrowserOptions(
          hideUrlBar: false,
        ),
        inAppWebViewGroupOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            contentBlockers: _contentBlockers,
            useOnDownloadStart: true,
            useShouldOverrideUrlLoading: true,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> onDownloadStartRequest(DownloadStartRequest downloadStartRequest) async {
    onDownloadStartCallback(downloadStartRequest);
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(NavigationAction navigationAction) async {
    final webUri = navigationAction.request.url;
    if (webUri == null) {
      return NavigationActionPolicy.ALLOW;
    }

    final scheme = webUri.scheme?.toLowerCase() ?? '';
    if (scheme == 'http' || scheme == 'https') {
      return NavigationActionPolicy.ALLOW;
    }

    if (scheme == 'intent') {
      final resolved = _resolveIntentUrl(webUri.toString());
      if (resolved != null) {
        if (resolved.scheme == 'http' || resolved.scheme == 'https') {
          await webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(resolved.toString())));
        } else {
          await _launchExternal(resolved);
        }
      }
      return NavigationActionPolicy.CANCEL;
    }

    final externalUri = Uri.tryParse(webUri.toString());
    if (externalUri != null) {
      await _launchExternal(externalUri);
    }
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _launchExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Uri? _resolveIntentUrl(String intentUrl) {
    const prefix = 'intent://';
    if (!intentUrl.startsWith(prefix)) {
      return null;
    }

    final intentIndex = intentUrl.indexOf('#Intent;');
    final basePart = intentIndex == -1
        ? intentUrl.substring(prefix.length)
        : intentUrl.substring(prefix.length, intentIndex);
    final paramsPart = intentIndex == -1
        ? ''
        : intentUrl.substring(intentIndex + '#Intent;'.length);

    final fallback = _extractIntentString(paramsPart, 'browser_fallback_url');
    if (fallback != null) {
      final uri = Uri.tryParse(fallback);
      if (uri != null) {
        return uri;
      }
    }

    final scheme = _extractIntentParam(paramsPart, 'scheme');
    if (scheme == null) {
      return null;
    }

    return Uri.tryParse('$scheme://$basePart');
  }

  String? _extractIntentParam(String paramsPart, String key) {
    final parts = paramsPart.split(';');
    for (final part in parts) {
      if (part.startsWith('$key=')) {
        return part.substring(key.length + 1);
      }
    }
    return null;
  }

  String? _extractIntentString(String paramsPart, String key) {
    final prefix = 'S.$key=';
    final parts = paramsPart.split(';');
    for (final part in parts) {
      if (part.startsWith(prefix)) {
        return Uri.decodeComponent(part.substring(prefix.length));
      }
    }
    return null;
  }
}