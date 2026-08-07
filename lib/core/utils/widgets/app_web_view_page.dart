import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Generic in-app browser that renders [url] inside a [WebView].
///
/// Handles the common edge cases so callers don't have to:
///   * empty / malformed URL            → inline "unavailable" error + close
///   * page still loading               → linear progress bar (real %)
///   * main-frame load / network error  → error state with a Retry button
///   * back navigation                  → pops in-page history first, else the
///                                        route (via [PopScope]).
///
/// Only `https`/`http` schemes are loaded; any other scheme (mailto:, tel:,
/// intent:, custom app links) is blocked to keep the surface safe.
class AppWebViewPage extends StatefulWidget {
  const AppWebViewPage({super.key, required this.url, required this.title});

  /// The absolute URL to open. May be empty — handled gracefully.
  final String url;

  /// AppBar title.
  final String title;

  @override
  State<AppWebViewPage> createState() => _AppWebViewPageState();
}

class _AppWebViewPageState extends State<AppWebViewPage> {
  WebViewController? _controller;

  /// Set once when the URL is missing/unparseable — the WebView is never built.
  bool _invalidUrl = false;

  /// True while the main frame is loading.
  bool _isLoading = true;

  /// Non-null when the main frame failed to load; drives the error overlay.
  String? _loadError;

  /// Load progress in the [0, 1] range for the linear indicator.
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final uri = Uri.tryParse(widget.url.trim());
    final isValid = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host.isNotEmpty);

    if (!isValid) {
      _invalidUrl = true;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.whiteColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress / 100.0);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Only surface failures of the top-level document; sub-resource
            // errors (an image, a tracker) must not blank out a good page.
            if (!mounted || error.isForMainFrame == false) return;
            setState(() {
              _isLoading = false;
              _loadError = _messageForError(error);
            });
          },
          onNavigationRequest: (request) {
            final scheme = Uri.tryParse(request.url)?.scheme.toLowerCase();
            if (scheme == 'https' || scheme == 'http') {
              return NavigationDecision.navigate;
            }
            // Block mailto:, tel:, intent:, custom schemes, etc.
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(uri);
  }

  String _messageForError(WebResourceError error) {
    switch (error.errorType) {
      case WebResourceErrorType.hostLookup:
      case WebResourceErrorType.connect:
      case WebResourceErrorType.timeout:
      case WebResourceErrorType.io:
        return 'No internet connection. Please check your network and try '
            'again.';
      default:
        return "This page couldn't be loaded. Please try again.";
    }
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
      _progress = 0;
    });
    await controller.reload();
  }

  /// Leaves this screen. Back always exits the WebView rather than walking the
  /// page's internal redirect history (which can trap the user on sites that
  /// redirect on load).
  void _handleBack() {
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ui.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ui.textPrimary),
          onPressed: _handleBack,
        ),
        title: AppText(
          widget.title,
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        centerTitle: false,
        bottom: (_isLoading && !_invalidUrl && _loadError == null)
            ? PreferredSize(
                preferredSize: Size.fromHeight(2.h),
                child: LinearProgressIndicator(
                  value: _progress > 0 && _progress < 1 ? _progress : null,
                  minHeight: 2.h,
                  backgroundColor: AppColors.transparentColor,
                  valueColor: AlwaysStoppedAnimation<Color>(ui.brandPrimary),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Container(
          color: AppColors.whiteColor,
          padding: EdgeInsets.all(16.w),
          child: _buildBody(ui),
        ),
      ),
    );
  }

  Widget _buildBody(AppUiColors ui) {
    if (_invalidUrl) {
      return _StateMessage(
        icon: Icons.link_off_rounded,
        message: 'This page is currently unavailable.',
        primaryLabel: 'Close',
        onPrimary: () => Navigator.of(context).maybePop(),
      );
    }

    if (_loadError != null) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        message: _loadError!,
        primaryLabel: 'Retry',
        onPrimary: _reload,
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(
              color: ui.brandPrimary,
              strokeWidth: 2.5,
            ),
          ),
      ],
    );
  }
}

/// Full-screen icon + message + single action, matching the profile error view.
class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final IconData icon;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: AppUtils.horizontal16Padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.iconsGreyColor, size: 48.r),
          16.verticalSpace,
          AppText(
            message,
            color: ui.textPrimary.withValues(alpha: 0.85),
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
          ),
          24.verticalSpace,
          PrimaryButtonWidget(
            text: primaryLabel,
            onPress: onPrimary,
            buttonWidth: double.infinity,
            buttonHeight: 38.h,
            cornerRadius: 12.r,
            buttonColor: ui.brandPrimary,
            textColor: AppColors.whiteColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight600,
          ),
        ],
      ),
    );
  }
}
