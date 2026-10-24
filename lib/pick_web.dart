import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Plain <input type=file> picker for the web build.
Future<Uint8List?> pickImageWeb({bool camera = false}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..style.display = 'none';
  if (camera) input.setAttribute('capture', 'environment');
  web.document.body?.append(input);
  final c = Completer<Uint8List?>();
  input.onchange = ((web.Event _) {
    final f = input.files?.item(0);
    if (f == null) {
      c.complete(null);
      return;
    }
    final r = web.FileReader();
    r.onload = ((web.Event _) {
      final buf = (r.result as JSArrayBuffer).toDart;
      c.complete(buf.asUint8List());
    }).toJS;
    r.onerror = ((web.Event _) => c.complete(null)).toJS;
    r.readAsArrayBuffer(f);
  }).toJS;
  input.click();
  final out = await c.future;
  input.remove();
  return out;
}
