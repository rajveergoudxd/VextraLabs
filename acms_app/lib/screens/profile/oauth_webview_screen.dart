import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:acms_app/theme/app_theme.dart';

/// Result of OAuth WebView flow
class OAuthResult {
  final String code;
  final String state;

  OAuthResult({required this.code, required this.state});
}

/// OAuth WebView screen for handling OAuth authorization flows
class OAuthWebViewScreen extends StatefulWidget {
  final String platform;
  final String authorizationUrl;
  final String redirectUri;
  final String state;

  const OAuthWebViewScreen({
    super.key,
    required this.platform,
    required this.authorizationUrl,
    required this.redirectUri,
    required this.state,
  });

  @override
  State<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends State<OAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100 && mounted) {
              setState(() => _isLoading = false);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Ignore errors for the redirect URL itself
            if (!error.url.toString().startsWith(widget.redirectUri)) {
              if (mounted) {
                setState(() {
                  _error = 'Failed to load: ${error.description}';
                  _isLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if this is the callback URL
            if (request.url.startsWith(widget.redirectUri)) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  void _handleCallback(String url) {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      if (error != null) {
        // OAuth error returned by the platform
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorDescription ?? 'Authorization denied: $error'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (code != null && state != null) {
        // Verify state matches
        if (state != widget.state) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Security error: State mismatch'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Return the OAuth result
        Navigator.of(context).pop(OAuthResult(code: code, state: state));
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authorization failed: Missing code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing callback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platformTitle =
        widget.platform[0].toUpperCase() + widget.platform.substring(1);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Connect $platformTitle',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.textMain,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _controller.loadRequest(
                        Uri.parse(widget.authorizationUrl),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),

          if (_isLoading)
            Container(
              color:
                  (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight)
                      .withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading authorization page...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
