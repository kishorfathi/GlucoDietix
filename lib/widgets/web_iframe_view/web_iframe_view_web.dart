import 'package:flutter/widgets.dart';
// ignore: deprecated_member_use
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void registerWebIFrameView({
  required String viewType,
  required String src,
  required bool allowCamera,
}) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = allowCamera ? 'camera; microphone; autoplay; fullscreen' : '';
      return iframe;
    },
  );
}

Widget buildWebIFrameView({
  required BuildContext context,
  required String viewType,
  Widget? nonWebFallback,
}) {
  return HtmlElementView(viewType: viewType);
}
