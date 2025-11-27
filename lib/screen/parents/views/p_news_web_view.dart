import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class FullArticleWebView extends StatefulWidget {
  final String url;
  const FullArticleWebView({super.key, required this.url});

  @override
  State<FullArticleWebView> createState() => _FullArticleWebViewState();
}

class _FullArticleWebViewState extends State<FullArticleWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Create platform-specific WebView params
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS || Platform.isMacOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => debugPrint('Loading: $progress%'),
          onPageStarted: (url) => debugPrint('Started: $url'),
          onPageFinished: (url) => debugPrint('Finished: $url'),
          onNavigationRequest: (request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (message) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message.message)));
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    if (!kIsWeb && !Platform.isMacOS) {
      controller.setBackgroundColor(const Color(0x00000000));
    }

    if (Platform.isAndroid) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autism News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
