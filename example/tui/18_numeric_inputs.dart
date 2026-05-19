import 'package:commander_ui/tui.dart';

class State {
  final volume = SliderState(value: 50);
  final brightness = SliderState(value: 80);
  final priceRange = RangeState(low: 20, high: 60);
  final date = DatePickerState(selected: DateTime(2026, 5, 14));
  final port = InputNumberState(initialValue: 8080);
  final scale = InputNumberState(initialValue: 1.5);

  num volumeValue = 50;
  num brightnessValue = 80;
  num priceLow = 20;
  num priceHigh = 60;
  DateTime? dateValue;
  num? portValue;
  num? scaleValue;
}

Future<void> main() => runTerminal<State>(
      initialState: State(),
      mode: const RenderMode.flow(height: 24),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q' && event.ctrl) {
          handle.stop();
        }
      },
      render: (ctx, state) {
        final rows = Layout.vertical([
          const Constraint.length(2), // title
          const Constraint.length(1), // section: sliders
          const Constraint.length(1), // volume
          const Constraint.length(1), // brightness
          const Constraint.length(1), // spacer
          const Constraint.length(1), // section: range
          const Constraint.length(1), // price range
          const Constraint.length(1), // spacer
          const Constraint.length(1), // section: number inputs
          const Constraint.length(1), // port
          const Constraint.length(1), // scale
          const Constraint.length(1), // spacer
          const Constraint.length(1), // section: date
          const Constraint.length(8), // date picker
          const Constraint.fill(1), // help
          const Constraint.length(1), // footer
        ]).split(ctx.area);

        ctx.draw(
          Text('Numeric inputs showcase',
              style: ctx.theme.text.title.copyWith(bold: true)),
          rows[0],
        );

        ctx.draw(
          Text('— Sliders (←/→, PgUp/Dn, Home/End)',
              style: Style(fg: ctx.theme.colors.muted)),
          rows[1],
        );

        ctx.draw(
          Slider(
            state: state.volume,
            min: 0,
            max: 100,
            step: 5,
            onChanged: (v) => state.volumeValue = v,
          ),
          rows[2],
        );

        ctx.draw(
          Slider(
            state: state.brightness,
            min: 0,
            max: 100,
            step: 1,
            onChanged: (v) => state.brightnessValue = v,
          ),
          rows[3],
        );

        ctx.draw(
          Text('— Range (Tab to switch handle)',
              style: Style(fg: ctx.theme.colors.muted)),
          rows[5],
        );

        ctx.draw(
          Range(
            state: state.priceRange,
            min: 0,
            max: 100,
            step: 1,
            formatValue: (v) => '\$${v.toInt()}',
            onChanged: (lo, hi) {
              state.priceLow = lo;
              state.priceHigh = hi;
            },
          ),
          rows[6],
        );

        ctx.draw(
          Text('— Number inputs (↑/↓ to step)',
              style: Style(fg: ctx.theme.colors.muted)),
          rows[8],
        );

        ctx.draw(
          InputNumber(
            state: state.port,
            message: 'Port',
            min: 1,
            max: 65535,
            step: 1,
            onSubmit: (v) => state.portValue = v,
          ),
          rows[9],
        );

        ctx.draw(
          InputNumber(
            state: state.scale,
            message: 'Scale',
            min: 0.1,
            max: 10,
            step: 0.1,
            allowDecimals: true,
            onSubmit: (v) => state.scaleValue = v,
          ),
          rows[10],
        );

        ctx.draw(
          Text('— Date picker (←/→ day, ↑/↓ week, PgUp/Dn month, [/] year)',
              style: Style(fg: ctx.theme.colors.muted)),
          rows[12],
        );

        ctx.draw(
          DatePicker(
            state: state.date,
            min: DateTime(2020),
            max: DateTime(2030, 12, 31),
            onSubmit: (d) => state.dateValue = d,
          ),
          rows[13],
        );

        final summary = StringBuffer()
          ..writeln(
              'volume=${state.volumeValue}  brightness=${state.brightnessValue}')
          ..writeln(
              'price=\$${state.priceLow.toInt()}–\$${state.priceHigh.toInt()}')
          ..writeln(
              'port=${state.portValue ?? "(unsubmitted)"}  scale=${state.scaleValue ?? "(unsubmitted)"}')
          ..writeln('date=${state.dateValue ?? "(unsubmitted)"}');

        ctx.draw(
          Paragraph(summary.toString(), style: ctx.theme.text.caption),
          rows[14],
        );

        ctx.draw(
          const Text(
              'Tab/Shift+Tab to navigate · Enter to submit · Ctrl-Q to quit',
              align: TextAlign.center),
          rows[15],
        );
      },
    );
