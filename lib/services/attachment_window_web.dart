import 'package:web/web.dart' as web;

/// Keep the click gesture while the API authorizes access to the private file.
class AttachmentWindow {
  AttachmentWindow._(this._window);
  final web.Window _window;
  static AttachmentWindow? reserve() {
    final opened = web.window.open('about:blank', '_blank');
    if (opened == null) return null;
    opened.opener = null;
    opened.document.title = 'Arquivo da pista — Educação OnLIFE';
    opened.document.body?.textContent = 'Preparando acesso ao arquivo…';
    return AttachmentWindow._(opened);
  }

  bool navigate(Uri uri) {
    if (_window.closed) return false;
    _window.location.replace(uri.toString());
    return true;
  }

  void close() {
    if (!_window.closed) _window.close();
  }
}
