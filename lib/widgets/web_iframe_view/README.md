# WebIFrameView

A tiny helper to embed web-only `<iframe>` content in a Flutter app without breaking desktop/mobile builds.

- **Web**: registers an iframe with `platformViewRegistry` and renders it via `HtmlElementView`.
- **Non-web**: returns a fallback widget (defaults to a short message).

## Usage

```dart
final id = 'some-unique-id';
final url = 'https://example.com/page.html';

WebIFrameView.register(viewType: id, src: url, allowCamera: true);

return WebIFrameView(
  viewType: id,
  src: url,
  allowCamera: true,
  nonWebFallback: const Center(child: Text('Open this feature on Web.')),
);
```

