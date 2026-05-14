import '../geometry/size.dart';
import '../style/style.dart';
import 'ansi_encoder.dart';
import 'buffer.dart';
import 'cell.dart';

class Renderer {
  final AnsiEncoder encoder;
  Buffer? _front;
  bool _initialPaint = true;
  int yOffset = 0;

  Renderer(this.encoder);

  void forceRepaint() {
    _initialPaint = true;
    _front = null;
  }

  void resize(Size newSize) {
    if (_front != null && _front!.size == newSize) return;
    _front = Buffer(newSize);
    _initialPaint = true;
  }

  String paint(Buffer back) {
    assert(back.width > 0 && back.height > 0,
        'Renderer.paint: back buffer must be non-empty (got ${back.width}x${back.height})');
    if (_front == null || _front!.size != back.size) {
      _front = Buffer(back.size);
      _initialPaint = true;
    }
    assert(_front!.size == back.size,
        'Renderer invariant broken: front/back size mismatch ${_front!.size} vs ${back.size}');
    final sb = StringBuffer();
    final w = back.width;
    final h = back.height;

    Style? lastStyle;
    int? lastX;
    int? lastY;

    void emit(Cell cell, int x, int y) {
      if (cell.width == 0) return;
      if (lastY != y || lastX != x) {
        sb.write(AnsiSequences.moveTo(x, y + yOffset));
      }
      if (lastStyle != cell.style) {
        sb.write(encoder.reset());
        final seq = encoder.encodeStyle(cell.style);
        if (seq.isNotEmpty) sb.write(seq);
        lastStyle = cell.style;
      }
      sb.write(cell.char.isEmpty ? ' ' : cell.char);
      final nextX = x + cell.width;
      lastX = nextX < w ? nextX : null;
      lastY = nextX < w ? y : null;
    }

    if (_initialPaint) {
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final cell = back.get(x, y);
          emit(cell, x, y);
          if (cell.width > 1) x += cell.width - 1;
          _front!.set(x, y, cell);
        }
      }
      _initialPaint = false;
    } else {
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final cell = back.get(x, y);
          final prev = _front!.get(x, y);
          if (cell != prev) {
            emit(cell, x, y);
            _front!.set(x, y, cell);
          }
          if (cell.width > 1) {
            x += cell.width - 1;
          }
        }
      }
    }

    if (lastStyle != null && lastStyle != Style.none) {
      sb.write(encoder.reset());
    }

    return sb.toString();
  }
}
