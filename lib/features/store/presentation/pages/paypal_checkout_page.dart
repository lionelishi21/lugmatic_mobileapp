import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// Opens a PayPal order's approval URL in an in-app WebView. Resolves with
/// `true` once the user is redirected back to our return URL (approved),
/// `false` if redirected to the cancel URL or the user backs out, and `null`
/// is never returned — the page always pops with an explicit result.
///
/// Matches the return/cancel URLs paypalService.js sets by default:
///   PAYPAL_RETURN_URL  (default https://lugmaticmusic.com/paypal/return)
///   PAYPAL_CANCEL_URL  (default https://lugmaticmusic.com/paypal/cancel)
class PayPalCheckoutPage extends StatefulWidget {
  final String approveUrl;
  final String returnUrlPrefix;
  final String cancelUrlPrefix;

  const PayPalCheckoutPage({
    super.key,
    required this.approveUrl,
    this.returnUrlPrefix = 'https://lugmaticmusic.com/paypal/return',
    this.cancelUrlPrefix = 'https://lugmaticmusic.com/paypal/cancel',
  });

  @override
  State<PayPalCheckoutPage> createState() => _PayPalCheckoutPageState();
}

class _PayPalCheckoutPageState extends State<PayPalCheckoutPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith(widget.returnUrlPrefix)) {
              _resolve(true);
              return NavigationDecision.prevent;
            }
            if (url.startsWith(widget.cancelUrlPrefix)) {
              _resolve(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approveUrl));
  }

  void _resolve(bool approved) {
    if (_resolved || !mounted) return;
    _resolved = true;
    Navigator.of(context).pop(approved);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _resolve(false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _resolve(false),
          ),
          title: const Text('PayPal Checkout', style: TextStyle(color: Colors.white)),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
