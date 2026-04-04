import 'package:flutter/widgets.dart';

void registerWebIFrameView({
  required String viewType,
  required String src,
  required bool allowCamera,
}) {
  // No-op on non-web platforms.
}

Widget buildWebIFrameView({
  required BuildContext context,
  required String viewType,
  Widget? nonWebFallback,
}) {
  return nonWebFallback ??
      const Center(
        child: Text(
          'AR view is only available on Web.',
          textAlign: TextAlign.center,
        ),
      );
}
