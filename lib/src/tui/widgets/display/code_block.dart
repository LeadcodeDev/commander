import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/event.dart';
import '../../runtime/key.dart';
import '../../runtime/render_context.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

enum CodeLanguage { plain, dart, json, shell, yaml }

/// Holds vertical scroll position for a [CodeBlock] in scrollable mode.
/// Lives on the caller's state so scroll is preserved across rebuilds.
class CodeBlockState {
  int scrollOffset;
  CodeBlockState({this.scrollOffset = 0});
}

class CodeTheme {
  final Style keyword;
  final Style string;
  final Style number;
  final Style comment;
  final Style identifier;
  final Style punctuation;
  final Style lineNumber;
  final Style background;

  const CodeTheme({
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
    required this.identifier,
    required this.punctuation,
    required this.lineNumber,
    this.background = const Style(),
  });

  static CodeTheme defaultFor(RenderContext ctx) => CodeTheme(
        keyword: Style(fg: ctx.theme.colors.primary, bold: true),
        string: Style(fg: ctx.theme.colors.success),
        number: Style(fg: ctx.theme.colors.warning),
        comment: Style(fg: ctx.theme.colors.muted, italic: true),
        identifier: ctx.theme.text.body,
        punctuation: Style(fg: ctx.theme.colors.muted),
        lineNumber: Style(fg: ctx.theme.colors.muted),
      );
}

class _Token {
  final String text;
  final Style style;
  _Token(this.text, this.style);
}

class CodeBlock implements FocusableWidget {
  static const _dartKeywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };
  static const _shellKeywords = {
    'if',
    'then',
    'else',
    'elif',
    'fi',
    'case',
    'esac',
    'for',
    'in',
    'do',
    'done',
    'while',
    'until',
    'function',
    'return',
    'export',
    'local',
    'readonly',
    'set',
    'unset',
    'declare',
    'echo',
    'cd',
    'exit',
    'source',
  };

  final Key? _id;
  @override
  Key get id => _id ?? ValueKey(state ?? code);

  final String code;
  final CodeLanguage language;
  final bool showLineNumbers;
  final int firstLineNumber;
  final CodeTheme? theme;

  /// When true the widget becomes focusable and reacts to ↑/↓/PgUp/PgDn/
  /// Home/End to scroll its content vertically. A [CodeBlockState] is
  /// required to persist the scroll offset across frames.
  final bool scrollable;
  final CodeBlockState? state;
  final int pageStep;

  const CodeBlock({
    Key? id,
    required this.code,
    this.language = CodeLanguage.plain,
    this.showLineNumbers = false,
    this.firstLineNumber = 1,
    this.theme,
    this.scrollable = false,
    this.state,
    this.pageStep = 5,
  })  : _id = id,
        assert(!scrollable || state != null,
            'CodeBlock(scrollable: true) requires a CodeBlockState');

  @override
  bool get isSkipped => !scrollable;

  @override
  void registerHitZones(Rect area, HitZoneSink sink) => sink.add(area, id);

  int _maxOffset(int totalLines, int viewportHeight) {
    final overflow = totalLines - viewportHeight;
    return overflow > 0 ? overflow : 0;
  }

  @override
  bool onKey(KeyEvent event, RenderContext ctx) {
    if (!scrollable) return false;
    final s = state!;
    final lines = code.split('\n').length;
    // Without a precise viewport here we clamp conservatively; the renderer
    // re-clamps against the actual visible height on the next draw.
    final maxOff = lines > 0 ? lines - 1 : 0;
    switch (event.key) {
      case NamedKey.arrowUp:
        if (s.scrollOffset > 0) s.scrollOffset--;
        return true;
      case NamedKey.arrowDown:
        if (s.scrollOffset < maxOff) s.scrollOffset++;
        return true;
      case NamedKey.pageUp:
        s.scrollOffset = (s.scrollOffset - pageStep).clamp(0, maxOff);
        return true;
      case NamedKey.pageDown:
        s.scrollOffset = (s.scrollOffset + pageStep).clamp(0, maxOff);
        return true;
      case NamedKey.home:
        s.scrollOffset = 0;
        return true;
      case NamedKey.end:
        s.scrollOffset = maxOff;
        return true;
      default:
        return false;
    }
  }

  CodeTheme _theme(RenderContext ctx) => theme ?? CodeTheme.defaultFor(ctx);

  List<_Token> _tokenize(String line, CodeTheme t) {
    switch (language) {
      case CodeLanguage.plain:
        return [_Token(line, t.identifier)];
      case CodeLanguage.dart:
        return _tokenizeDart(line, t);
      case CodeLanguage.json:
        return _tokenizeJson(line, t);
      case CodeLanguage.shell:
        return _tokenizeShell(line, t);
      case CodeLanguage.yaml:
        return _tokenizeYaml(line, t);
    }
  }

  List<_Token> _tokenizeDart(String line, CodeTheme t) {
    final tokens = <_Token>[];
    var i = 0;
    while (i < line.length) {
      final c = line[i];
      // Line comment.
      if (i + 1 < line.length && c == '/' && line[i + 1] == '/') {
        tokens.add(_Token(line.substring(i), t.comment));
        return tokens;
      }
      // Strings.
      if (c == "'" || c == '"') {
        final quote = c;
        var j = i + 1;
        while (j < line.length && line[j] != quote) {
          if (line[j] == r'\' && j + 1 < line.length)
            j += 2;
          else
            j++;
        }
        if (j < line.length) j++;
        tokens.add(_Token(line.substring(i, j), t.string));
        i = j;
        continue;
      }
      // Numbers.
      if (_isDigit(c)) {
        var j = i;
        while (j < line.length && (_isDigit(line[j]) || line[j] == '.')) {
          j++;
        }
        tokens.add(_Token(line.substring(i, j), t.number));
        i = j;
        continue;
      }
      // Identifiers / keywords.
      if (_isIdentStart(c)) {
        var j = i;
        while (j < line.length && _isIdentPart(line[j])) {
          j++;
        }
        final word = line.substring(i, j);
        tokens.add(_Token(
            word, _dartKeywords.contains(word) ? t.keyword : t.identifier));
        i = j;
        continue;
      }
      // Punctuation / whitespace.
      tokens.add(_Token(c, _isPunct(c) ? t.punctuation : t.identifier));
      i++;
    }
    return tokens;
  }

  List<_Token> _tokenizeJson(String line, CodeTheme t) {
    final tokens = <_Token>[];
    var i = 0;
    while (i < line.length) {
      final c = line[i];
      if (c == '"') {
        var j = i + 1;
        while (j < line.length && line[j] != '"') {
          if (line[j] == r'\' && j + 1 < line.length)
            j += 2;
          else
            j++;
        }
        if (j < line.length) j++;
        final str = line.substring(i, j);
        // If followed by ':', treat as key (keyword).
        var k = j;
        while (k < line.length && line[k] == ' ') k++;
        final isKey = k < line.length && line[k] == ':';
        tokens.add(_Token(str, isKey ? t.keyword : t.string));
        i = j;
        continue;
      }
      if (_isDigit(c) ||
          (c == '-' && i + 1 < line.length && _isDigit(line[i + 1]))) {
        var j = i + 1;
        while (j < line.length &&
            (_isDigit(line[j]) ||
                line[j] == '.' ||
                line[j] == 'e' ||
                line[j] == 'E' ||
                line[j] == '+' ||
                line[j] == '-')) {
          j++;
        }
        tokens.add(_Token(line.substring(i, j), t.number));
        i = j;
        continue;
      }
      if (_isIdentStart(c)) {
        var j = i;
        while (j < line.length && _isIdentPart(line[j])) {
          j++;
        }
        final word = line.substring(i, j);
        final isLiteral = word == 'true' || word == 'false' || word == 'null';
        tokens.add(_Token(word, isLiteral ? t.keyword : t.identifier));
        i = j;
        continue;
      }
      tokens.add(_Token(c, _isPunct(c) ? t.punctuation : t.identifier));
      i++;
    }
    return tokens;
  }

  List<_Token> _tokenizeShell(String line, CodeTheme t) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('#')) {
      return [_Token(line, t.comment)];
    }
    final tokens = <_Token>[];
    var i = 0;
    while (i < line.length) {
      final c = line[i];
      if (c == "'" || c == '"') {
        final quote = c;
        var j = i + 1;
        while (j < line.length && line[j] != quote) {
          if (line[j] == r'\' && j + 1 < line.length)
            j += 2;
          else
            j++;
        }
        if (j < line.length) j++;
        tokens.add(_Token(line.substring(i, j), t.string));
        i = j;
        continue;
      }
      if (c == r'$' && i + 1 < line.length) {
        var j = i + 1;
        if (line[j] == '{') {
          while (j < line.length && line[j] != '}') {
            j++;
          }
          if (j < line.length) j++;
        } else {
          while (j < line.length && _isIdentPart(line[j])) {
            j++;
          }
        }
        tokens.add(_Token(line.substring(i, j), t.number));
        i = j;
        continue;
      }
      if (_isIdentStart(c)) {
        var j = i;
        while (j < line.length && _isIdentPart(line[j])) {
          j++;
        }
        final word = line.substring(i, j);
        tokens.add(_Token(
            word, _shellKeywords.contains(word) ? t.keyword : t.identifier));
        i = j;
        continue;
      }
      tokens.add(_Token(c, _isPunct(c) ? t.punctuation : t.identifier));
      i++;
    }
    return tokens;
  }

  List<_Token> _tokenizeYaml(String line, CodeTheme t) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('#')) {
      return [_Token(line, t.comment)];
    }
    // Find first colon outside quotes.
    var colonIdx = -1;
    var inQuote = false;
    String? quoteChar;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuote) {
        if (c == quoteChar) inQuote = false;
      } else if (c == "'" || c == '"') {
        inQuote = true;
        quoteChar = c;
      } else if (c == ':') {
        colonIdx = i;
        break;
      }
    }
    if (colonIdx > 0) {
      return [
        _Token(line.substring(0, colonIdx), t.keyword),
        _Token(':', t.punctuation),
        _Token(line.substring(colonIdx + 1), t.string),
      ];
    }
    return [_Token(line, t.identifier)];
  }

  static bool _isDigit(String c) {
    final cp = c.codeUnitAt(0);
    return cp >= 0x30 && cp <= 0x39;
  }

  static bool _isIdentStart(String c) {
    final cp = c.codeUnitAt(0);
    return (cp >= 0x41 && cp <= 0x5A) ||
        (cp >= 0x61 && cp <= 0x7A) ||
        cp == 0x5F;
  }

  static bool _isIdentPart(String c) => _isIdentStart(c) || _isDigit(c);

  static bool _isPunct(String c) {
    const punct = '(){}[];,.:?@#=+-*/<>!&|^~%';
    return punct.contains(c);
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    final t = _theme(ctx);
    final lines = code.split('\n');
    final lineNoWidth = showLineNumbers
        ? (lines.length + firstLineNumber - 1).toString().length
        : 0;
    final lineNoGutter = showLineNumbers ? lineNoWidth + 1 : 0;

    int offset = 0;
    if (scrollable) {
      final maxOff = _maxOffset(lines.length, area.height);
      state!.scrollOffset = state!.scrollOffset.clamp(0, maxOff);
      offset = state!.scrollOffset;
    }

    for (var i = 0; i < area.height && (i + offset) < lines.length; i++) {
      final lineIndex = i + offset;
      final y = area.y + i;
      var x = area.x;
      if (showLineNumbers) {
        final n = (lineIndex + firstLineNumber).toString().padLeft(lineNoWidth);
        buffer.writeText(x, y, n, style: t.lineNumber, maxWidth: lineNoWidth);
        x += lineNoGutter;
      }
      final tokens = _tokenize(lines[lineIndex], t);
      for (final tok in tokens) {
        if (x >= area.right) break;
        final remaining = area.right - x;
        final shown = tok.text.length > remaining
            ? tok.text.substring(0, remaining)
            : tok.text;
        buffer.writeText(x, y, shown, style: tok.style, maxWidth: remaining);
        x += shown.length;
      }
    }
  }
}
