import 'package:flutter/widgets.dart';

import 'web_iframe_view_stub.dart'
    if (dart.library.html) 'web_iframe_view_web.dart' as impl;

/// Cross-platform iframe widget.
///
/// - On web: renders an actual `<iframe>` using `HtmlElementView`.
/// - On non-web (Windows/Android/iOS/etc): shows a simple fallback UI.
class WebIFrameView extends StatelessWidget {
  final String viewType;

  /// The iframe URL to load.
  ///
  /// On web, you usually set this when calling [WebIFrameView.register].
  /// For convenience, this is optional when *rendering* the view.
  final String? src;

  final bool allowCamera;

  /// Optional widget to show on non-web platforms.
  final Widget? nonWebFallback;

  const WebIFrameView({
    super.key,
    required this.viewType,
    this.src,
    this.allowCamera = false,
    this.nonWebFallback,
  });

  /// Registers a view factory on web. Safe to call on any platform.
  static void register({
    required String viewType,
    required String src,
    bool allowCamera = false,
  }) {
    impl.registerWebIFrameView(
      viewType: viewType,
      src: src,
      allowCamera: allowCamera,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If a src is provided but wasn't registered yet, register it.
    // (No-op on non-web.)
    final localSrc = src;
    if (localSrc != null && localSrc.isNotEmpty) {
      register(viewType: viewType, src: localSrc, allowCamera: allowCamera);
    }

    return impl.buildWebIFrameView(
      context: context,
      viewType: viewType,
      nonWebFallback: nonWebFallback,
    );
  }
}
