import '../runtime/event.dart';

class KeyDecoder {
  final List<int> _buffer = [];

  Iterable<Event> decode(List<int> bytes) sync* {
    _buffer.addAll(bytes);
    while (_buffer.isNotEmpty) {
      final result = _decodeOne();
      if (result == null) return;
      yield result.event;
      _buffer.removeRange(0, result.consumed);
    }
  }

  ({Event event, int consumed})? _decodeOne() {
    if (_buffer.isEmpty) return null;
    final b0 = _buffer[0];

    if (b0 == 0x1B) {
      if (_buffer.length == 1) {
        return (event: const KeyEvent(key: NamedKey.escape), consumed: 1);
      }
      final b1 = _buffer[1];
      if (b1 == 0x1B) {
        return (event: const KeyEvent(key: NamedKey.escape), consumed: 1);
      }
      if (b1 == 0x5B) {
        return _decodeCsi();
      }
      if (b1 == 0x4F) {
        return _decodeSs3();
      }
      if (b1 >= 0x20 && b1 < 0x7F) {
        return (
          event:
              KeyEvent(char: String.fromCharCode(b1), alt: true, raw: [b0, b1]),
          consumed: 2,
        );
      }
      return (event: const KeyEvent(key: NamedKey.escape), consumed: 1);
    }

    if (b0 == 0x0D || b0 == 0x0A) {
      return (event: const KeyEvent(key: NamedKey.enter), consumed: 1);
    }
    if (b0 == 0x09) {
      return (event: const KeyEvent(key: NamedKey.tab), consumed: 1);
    }
    if (b0 == 0x7F || b0 == 0x08) {
      return (event: const KeyEvent(key: NamedKey.backspace), consumed: 1);
    }
    if (b0 == 0x20) {
      return (event: const KeyEvent(char: ' '), consumed: 1);
    }

    if (b0 < 0x20) {
      final letter = String.fromCharCode(b0 + 0x60);
      return (
        event: KeyEvent(char: letter, ctrl: true, raw: [b0]),
        consumed: 1,
      );
    }

    if (b0 < 0x80) {
      return (event: KeyEvent(char: String.fromCharCode(b0)), consumed: 1);
    }

    int seqLen;
    if ((b0 & 0xE0) == 0xC0) {
      seqLen = 2;
    } else if ((b0 & 0xF0) == 0xE0) {
      seqLen = 3;
    } else if ((b0 & 0xF8) == 0xF0) {
      seqLen = 4;
    } else {
      // Lone continuation byte or invalid lead — drop it.
      return (event: const KeyEvent(key: NamedKey.unknown), consumed: 1);
    }
    if (_buffer.length < seqLen) return null;
    for (var i = 1; i < seqLen; i++) {
      if ((_buffer[i] & 0xC0) != 0x80) {
        // Invalid continuation byte — drop the lead byte and resync.
        return (event: const KeyEvent(key: NamedKey.unknown), consumed: 1);
      }
    }
    final s = String.fromCharCodes(_buffer.sublist(0, seqLen));
    return (
      event: KeyEvent(char: s, raw: _buffer.sublist(0, seqLen)),
      consumed: seqLen,
    );
  }

  ({Event event, int consumed})? _decodeCsi() {
    var i = 2;
    final params = StringBuffer();
    while (i < _buffer.length) {
      final b = _buffer[i];
      if (b >= 0x30 && b <= 0x3F) {
        params.writeCharCode(b);
        i++;
        continue;
      }
      if (b >= 0x20 && b <= 0x2F) {
        params.writeCharCode(b);
        i++;
        continue;
      }
      if (b >= 0x40 && b <= 0x7E) {
        return _interpretCsi(params.toString(), String.fromCharCode(b), i + 1);
      }
      break;
    }
    return null;
  }

  ({Event event, int consumed})? _decodeSs3() {
    if (_buffer.length < 3) return null;
    final c = String.fromCharCode(_buffer[2]);
    final key = switch (c) {
      'A' => NamedKey.arrowUp,
      'B' => NamedKey.arrowDown,
      'C' => NamedKey.arrowRight,
      'D' => NamedKey.arrowLeft,
      'H' => NamedKey.home,
      'F' => NamedKey.end,
      'P' => NamedKey.f1,
      'Q' => NamedKey.f2,
      'R' => NamedKey.f3,
      'S' => NamedKey.f4,
      _ => null,
    };
    if (key != null) {
      return (event: KeyEvent(key: key), consumed: 3);
    }
    return (event: KeyEvent(char: c), consumed: 3);
  }

  ({Event event, int consumed})? _interpretCsi(
      String params, String finalByte, int consumed) {
    if (params.startsWith('<')) {
      final parts = params.substring(1).split(';');
      if (parts.length >= 3) {
        final code = int.tryParse(parts[0]) ?? 0;
        final x = (int.tryParse(parts[1]) ?? 1) - 1;
        final y = (int.tryParse(parts[2]) ?? 1) - 1;
        final isUp = finalByte == 'm';
        final button = switch (code & 0x43) {
          0 => MouseButton.left,
          1 => MouseButton.middle,
          2 => MouseButton.right,
          _ => MouseButton.none,
        };
        final isMotion = (code & 32) != 0;
        final isScroll = (code & 64) != 0;
        MouseAction action;
        if (isScroll) {
          action =
              (code & 1) == 1 ? MouseAction.scrollDown : MouseAction.scrollUp;
        } else if (isMotion) {
          action = MouseAction.move;
        } else if (isUp) {
          action = MouseAction.up;
        } else {
          action = MouseAction.down;
        }
        return (
          event: MouseEvent(
            x: x,
            y: y,
            button: button,
            action: action,
            shift: (code & 4) != 0,
            alt: (code & 8) != 0,
            ctrl: (code & 16) != 0,
          ),
          consumed: consumed,
        );
      }
    }

    final shift = finalByte == 'Z';
    final namedKey = switch (finalByte) {
      'A' => NamedKey.arrowUp,
      'B' => NamedKey.arrowDown,
      'C' => NamedKey.arrowRight,
      'D' => NamedKey.arrowLeft,
      'H' => NamedKey.home,
      'F' => NamedKey.end,
      'Z' => NamedKey.tab,
      '~' => _decodeTildeKey(params),
      _ => null,
    };

    if (namedKey != null) {
      return (event: KeyEvent(key: namedKey, shift: shift), consumed: consumed);
    }
    return (event: KeyEvent(char: finalByte, shift: shift), consumed: consumed);
  }

  NamedKey? _decodeTildeKey(String params) {
    final n = int.tryParse(params.split(';').first) ?? 0;
    return switch (n) {
      1 || 7 => NamedKey.home,
      2 => NamedKey.insert,
      3 => NamedKey.delete,
      4 || 8 => NamedKey.end,
      5 => NamedKey.pageUp,
      6 => NamedKey.pageDown,
      11 => NamedKey.f1,
      12 => NamedKey.f2,
      13 => NamedKey.f3,
      14 => NamedKey.f4,
      15 => NamedKey.f5,
      17 => NamedKey.f6,
      18 => NamedKey.f7,
      19 => NamedKey.f8,
      20 => NamedKey.f9,
      21 => NamedKey.f10,
      23 => NamedKey.f11,
      24 => NamedKey.f12,
      _ => NamedKey.unknown,
    };
  }
}
