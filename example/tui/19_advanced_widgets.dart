import 'dart:math';

import 'package:commander_ui/tui.dart';

class AppState {
  int tab = 0;

  // Tab 0 — Time & Scroll
  final time = TimePickerState(hour: 9, minute: 30);
  final scroll = ScrollViewState();

  // Tab 1 — Charts (live)
  final spark = <num>[for (var i = 0; i < 60; i++) 0];
  int frame = 0;

  // Tab 2 — TextArea
  final notes = TextAreaState(
    initialValue: 'Welcome to TextArea.\n\nType anywhere.\n'
        'Ctrl+Enter submits.\nArrows / Home / End / PgUp-Dn navigate.',
  );

  // Tab 3 — Tree
  final tree = TreeState<String>(expandedKeys: {'lib'});

  // Tab 4 — CodeBlock (scrollable)
  final codeScroll = CodeBlockState();

  // Used to drive Sparkline animation.
  AppState() {
    final rng = Random(42);
    for (var i = 0; i < spark.length; i++) {
      spark[i] = 30 + rng.nextDouble() * 40;
    }
  }
}

final _projectTree = <TreeNode<String>>[
  TreeNode(
    value: 'lib',
    label: 'lib/',
    children: [
      TreeNode(value: 'tui.dart', label: 'tui.dart'),
      TreeNode(
        value: 'src',
        label: 'src/',
        children: [
          TreeNode(value: 'rendering', label: 'rendering/'),
          TreeNode(value: 'runtime', label: 'runtime/'),
          TreeNode(value: 'widgets', label: 'widgets/'),
        ],
      ),
    ],
  ),
  TreeNode(
    value: 'test',
    label: 'test/',
    children: [
      TreeNode(value: 'tui', label: 'tui/'),
    ],
  ),
  TreeNode(
    value: 'example',
    label: 'example/',
    children: [
      TreeNode(value: '17', label: '17_input.dart'),
      TreeNode(value: '18', label: '18_numeric_inputs.dart'),
      TreeNode(value: '19', label: '19_advanced_widgets.dart'),
    ],
  ),
  TreeNode(value: 'pubspec', label: 'pubspec.yaml'),
];

const _sampleCode = '''
import 'package:commander_ui/tui.dart';

class State {
  final input = InputState();
  String? value;
}

Future<void> main() => runTerminal<State>(
  initialState: State(),
  mode: const RenderMode.flow(autoGrow: true),
  onEvent: (s, e, h) {
    if (e is KeyEvent && e.char == 'q' && e.ctrl) h.stop();
  },
  render: (ctx, state) {
    ctx.draw(
      Input(
        state: state.input,
        message: 'Your name?',
        onSubmit: (v) => state.value = v,
      ),
      ctx.area,
    );
  },
);
''';

Future<void> main() => runTerminal<AppState>(
      initialState: AppState(),
      mode: const RenderMode.alternateScreen(),
      frameRate: const Duration(milliseconds: 200),
      onEvent: (s, event, handle) {
        if (event is KeyEvent && event.char == 'q' && event.ctrl) {
          handle.stop();
        }
        if (event is TickEvent && s.tab == 1) {
          s.frame++;
          final rng = Random(s.frame);
          s.spark.removeAt(0);
          s.spark.add(30 + rng.nextDouble() * 40);
        }
      },
      render: (ctx, state) {
        if (ctx.area.height < 16 || ctx.area.width < 60) {
          ctx.draw(
            Center(
              child: Paragraph(
                'Terminal too small.\n\n'
                'Please resize to at least 60 × 16 (got '
                '${ctx.area.width} × ${ctx.area.height}).\n\n'
                'Ctrl-Q to quit.',
                style: Style(fg: ctx.theme.colors.warning, bold: true),
              ),
            ),
            ctx.area,
          );
          return;
        }
        final rows = Layout.vertical([
          const Constraint.length(2), // tabs
          const Constraint.fill(1), // body
          const Constraint.length(1), // footer
        ]).split(ctx.area);

        ctx.draw(
          Tabs(
            id: Key.symbol(#tabs),
            tabs: const [
              'Time + Scroll',
              'Charts',
              'TextArea',
              'Tree',
              'CodeBlock',
            ],
            selected: state.tab,
            onTabSelected: (i) => state.tab = i,
          ),
          rows[0],
        );

        switch (state.tab) {
          case 0:
            _renderTimeScroll(ctx, state, rows[1]);
          case 1:
            _renderCharts(ctx, state, rows[1]);
          case 2:
            _renderTextArea(ctx, state, rows[1]);
          case 3:
            _renderTree(ctx, state, rows[1]);
          default:
            _renderCodeBlock(ctx, state, rows[1]);
        }

        ctx.draw(
          const Text(
            'Tab/Shift+Tab: focus · h/l: switch tabs · Ctrl-Q: quit',
            align: TextAlign.center,
          ),
          rows[2],
        );
      },
    );

void _renderTimeScroll(RenderContext ctx, AppState state, Rect area) {
  final cols = Layout.horizontal([
    const Constraint.percentage(40),
    const Constraint.fill(1),
  ]).split(area);

  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' TimePicker ',
      padding: const EdgeInsets.all(1),
      child: TimePicker(
        state: state.time,
        showSeconds: true,
        use24Hour: true,
      ),
    ),
    cols[0],
  );

  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' ScrollView ',
      child: ScrollView(
        state: state.scroll,
        contentHeight: 40,
        child: Paragraph(
          List.generate(
                  40,
                  (i) => 'Line ${(i + 1).toString().padLeft(2)} — '
                      'lorem ipsum dolor sit amet, consectetur adipiscing.')
              .join('\n'),
        ),
      ),
    ),
    cols[1],
  );
}

void _renderCharts(RenderContext ctx, AppState state, Rect area) {
  final rows = Layout.vertical([
    const Constraint.length(3), // sparkline
    const Constraint.fill(1), // vertical bar chart
    const Constraint.length(7), // horizontal bar chart
  ]).split(area);

  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' Sparkline (live) ',
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Sparkline(values: state.spark),
    ),
    rows[0],
  );

  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' BarChart (vertical) ',
      padding: const EdgeInsets.all(1),
      child: BarChart(
        data: const [
          BarDatum('Jan', 32),
          BarDatum('Feb', 47),
          BarDatum('Mar', 28),
          BarDatum('Apr', 65),
          BarDatum('May', 51),
          BarDatum('Jun', 78),
          BarDatum('Jul', 92),
          BarDatum('Aug', 60),
        ],
        showValues: true,
        showLabels: true,
        barWidth: 4,
        gap: 2,
      ),
    ),
    rows[1],
  );

  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' BarChart (horizontal) ',
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: BarChart(
        orientation: BarOrientation.horizontal,
        data: [
          BarDatum('Dart', 87, style: Style(fg: ctx.theme.colors.primary)),
          BarDatum('Rust', 64, style: Style(fg: ctx.theme.colors.warning)),
          BarDatum('Go', 52, style: Style(fg: ctx.theme.colors.success)),
          BarDatum('Zig', 21, style: Style(fg: ctx.theme.colors.error)),
        ],
        showValues: true,
      ),
    ),
    rows[2],
  );
}

void _renderTextArea(RenderContext ctx, AppState state, Rect area) {
  ctx.draw(
    Container(
      border: BorderStyle.rounded,
      title: ' Notes (TextArea) ',
      padding: const EdgeInsets.all(1),
      child: TextArea(
        state: state.notes,
        placeholder: 'Type your notes here...',
        maxLines: 100,
      ),
    ),
    area,
  );
}

void _renderTree(RenderContext ctx, AppState state, Rect area) {
  final cols = Layout.horizontal([
    const Constraint.percentage(50),
    const Constraint.fill(1),
  ]).split(area);

  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' Project ',
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Tree<String>(
        state: state.tree,
        roots: _projectTree,
        keyOf: (node, path) => path.join('/'),
      ),
    ),
    cols[0],
  );

  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' Help ',
      padding: const EdgeInsets.all(1),
      child: const Paragraph(
        '↑/↓        Navigate\n'
        '→          Expand / dive in\n'
        '←          Collapse / jump to parent\n'
        'Enter/Space  Toggle\n'
        'Home/End   First / last',
      ),
    ),
    cols[1],
  );
}

void _renderCodeBlock(RenderContext ctx, AppState state, Rect area) {
  ctx.draw(
    Container(
      border: BorderStyle.single,
      title: ' Dart sample (↑/↓ PgUp/PgDn Home/End to scroll) ',
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: CodeBlock(
        id: Key.symbol(#codeBlock),
        code: _sampleCode,
        language: CodeLanguage.dart,
        showLineNumbers: true,
        scrollable: true,
        state: state.codeScroll,
      ),
    ),
    area,
  );
}
