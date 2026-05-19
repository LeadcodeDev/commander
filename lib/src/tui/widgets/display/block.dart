import '../../geometry/rect.dart';
import '../../rendering/buffer.dart';
import '../../runtime/render_context.dart';
import '../../style/border.dart';
import '../../style/style.dart';
import '../../widget/widget.dart';

enum TitleAlign { left, center, right }

class Block implements Widget {
  final BorderStyle? borderStyle;
  final BorderSides sides;
  final String? title;
  final TitleAlign titleAlign;
  final Style? borderColor;
  final Style? titleStyle;
  final Widget? child;
  final Style? fill;

  const Block({
    this.borderStyle,
    this.sides = BorderSides.all,
    this.title,
    this.titleAlign = TitleAlign.left,
    this.borderColor,
    this.titleStyle,
    this.child,
    this.fill,
  });

  factory Block.bordered({String? title, Widget? child, BorderStyle? style}) =>
      Block(
          borderStyle: style,
          sides: BorderSides.all,
          title: title,
          child: child);

  Block titled(String title) => Block(
        borderStyle: borderStyle,
        sides: sides,
        title: title,
        titleAlign: titleAlign,
        borderColor: borderColor,
        titleStyle: titleStyle,
        child: child,
        fill: fill,
      );

  Block withChild(Widget c) => Block(
        borderStyle: borderStyle,
        sides: sides,
        title: title,
        titleAlign: titleAlign,
        borderColor: borderColor,
        titleStyle: titleStyle,
        child: c,
        fill: fill,
      );

  Rect inner(Rect area) {
    final hasT = sides.hasTop ? 1 : 0;
    final hasB = sides.hasBottom ? 1 : 0;
    final hasL = sides.hasLeft ? 1 : 0;
    final hasR = sides.hasRight ? 1 : 0;
    return area.inset(top: hasT, bottom: hasB, left: hasL, right: hasR);
  }

  @override
  void render(Rect area, Buffer buffer, RenderContext ctx) {
    if (area.isEmpty) return;
    if (fill != null) {
      buffer.fillStyle(area, fill!);
    }
    final bs = borderStyle ?? ctx.theme.borders.style;
    final chars = bs.chars;
    final stroke = borderColor ?? ctx.theme.borders.strokeStyle;

    if (sides.hasTop && area.height >= 1) {
      for (var x = 0; x < area.width; x++) {
        buffer.setChar(area.x + x, area.y, chars.top, style: stroke);
      }
    }
    if (sides.hasBottom && area.height >= 2) {
      for (var x = 0; x < area.width; x++) {
        buffer.setChar(area.x + x, area.bottom - 1, chars.bottom,
            style: stroke);
      }
    }
    if (sides.hasLeft && area.width >= 1) {
      for (var y = 0; y < area.height; y++) {
        buffer.setChar(area.x, area.y + y, chars.left, style: stroke);
      }
    }
    if (sides.hasRight && area.width >= 2) {
      for (var y = 0; y < area.height; y++) {
        buffer.setChar(area.right - 1, area.y + y, chars.right, style: stroke);
      }
    }
    if (sides == BorderSides.all && area.width >= 2 && area.height >= 2) {
      buffer.setChar(area.x, area.y, chars.topLeft, style: stroke);
      buffer.setChar(area.right - 1, area.y, chars.topRight, style: stroke);
      buffer.setChar(area.x, area.bottom - 1, chars.bottomLeft, style: stroke);
      buffer.setChar(area.right - 1, area.bottom - 1, chars.bottomRight,
          style: stroke);
    }

    if (title != null && sides.hasTop && area.width > 2) {
      final ts = titleStyle ?? ctx.theme.text.title;
      final padded = ' $title ';
      final maxW = area.width - 2;
      final clipped = padded.length > maxW ? padded.substring(0, maxW) : padded;
      final tx = switch (titleAlign) {
        TitleAlign.left => area.x + 1,
        TitleAlign.center => area.x + (area.width - clipped.length) ~/ 2,
        TitleAlign.right => area.right - 1 - clipped.length,
      };
      buffer.writeText(tx, area.y, clipped, style: ts, maxWidth: maxW);
    }

    if (child != null) {
      ctx.draw(child!, inner(area));
    }
  }
}
