import 'color.dart';

class Style {
  final Color? fg;
  final Color? bg;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool dim;
  final bool reverse;
  final bool strikethrough;

  const Style({
    this.fg,
    this.bg,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.dim = false,
    this.reverse = false,
    this.strikethrough = false,
  });

  static const Style none = Style();

  Style copyWith({
    Color? fg,
    Color? bg,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? dim,
    bool? reverse,
    bool? strikethrough,
  }) =>
      Style(
        fg: fg ?? this.fg,
        bg: bg ?? this.bg,
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        dim: dim ?? this.dim,
        reverse: reverse ?? this.reverse,
        strikethrough: strikethrough ?? this.strikethrough,
      );

  /// Paint `this` on top of [other] — `this` wins where it sets a value.
  /// Mnemonic: `top.over(bottom)`.
  Style over(Style? other) {
    if (other == null) return this;
    return Style(
      fg: fg ?? other.fg,
      bg: bg ?? other.bg,
      bold: bold || other.bold,
      italic: italic || other.italic,
      underline: underline || other.underline,
      dim: dim || other.dim,
      reverse: reverse || other.reverse,
      strikethrough: strikethrough || other.strikethrough,
    );
  }

  /// Paint `this` underneath [other] — [other] wins where it sets a value.
  /// Mnemonic: `bottom.under(top)`. Equivalent to `other.over(this)`.
  Style under(Style? other) {
    if (other == null) return this;
    return other.over(this);
  }

  Style withFg(Color c) => copyWith(fg: c);
  Style withBg(Color c) => copyWith(bg: c);

  static Style bolded() => const Style(bold: true);
  static Style italicized() => const Style(italic: true);
  static Style underlined() => const Style(underline: true);
  static Style dimmed() => const Style(dim: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Style &&
          other.fg == fg &&
          other.bg == bg &&
          other.bold == bold &&
          other.italic == italic &&
          other.underline == underline &&
          other.dim == dim &&
          other.reverse == reverse &&
          other.strikethrough == strikethrough);

  @override
  int get hashCode => Object.hash(
        fg, bg, bold, italic, underline, dim, reverse, strikethrough,
      );
}
