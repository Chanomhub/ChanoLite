
import 'package:chanolite/managers/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppBrowserHelper extends InAppBrowser {
  final DownloadManager downloadManager;

  InAppBrowserHelper({required this.downloadManager});

  // A basic list of ad-related domains to block.
  static final List<String> _adBlockDomains = [
    '.doubleclick.net',
    '.googleadservices.com',
    '.googlesyndication.com',
    '.moat.com',
    '.admob.com',
    '.adservice.google.com',
    '.sourshaped.com',
    // Add more domains as needed
  ];

  static final List<ContentBlocker> _contentBlockers = _adBlockDomains.map((domain) {
    return ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: '.*$domain.*'),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    );
  }).toList();

  static String? _extractFilename(String? contentDisposition) {
    if (contentDisposition == null) {
      return null;
    }

    // Look for filename*=UTF-8''...
    // This is the modern way to encode filenames and supports unicode.
    final utf8FilenameRegex = RegExp(r"filename\*=UTF-8''(.+)");
    var match = utf8FilenameRegex.firstMatch(contentDisposition);
    if (match != null) {
      final encodedFilename = match.group(1);
      if (encodedFilename != null) {
        try {
          // URL-decode the filename
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
    {required DownloadManager downloadManager}
  ) async {
    final InAppBrowserHelper browser = InAppBrowserHelper(downloadManager: downloadManager);
    await browser.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(url)),
      options: InAppBrowserClassOptions(
        crossPlatform: InAppBrowserOptions(
          hideUrlBar: false,
        ),
        inAppWebViewGroupOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            contentBlockers: _contentBlockers,
            useOnDownloadStart: true, // This is crucial
          ),
        ),
      ),
    );
  }

  @override
  Future<void> onDownloadStartRequest(DownloadStartRequest downloadStartRequest) async {
    // Prioritize filename from Content-Disposition header, fallback to suggestedFilename
    final fileName = _extractFilename(downloadStartRequest.contentDisposition) ?? downloadStartRequest.suggestedFilename;

    // Instead of letting the webview download, we pass the url to our DownloadManager
    await downloadManager.startDownload(
      downloadStartRequest.url.toString(),
      suggestedFilename: fileName,
    );
  }
}
