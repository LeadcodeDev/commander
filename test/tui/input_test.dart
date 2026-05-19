import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

void main() {
  group('Input', () {
    test('renders message + askPrefix', () {
      final state = InputState();
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Your name?',
        state: state,
      );
      final buf = renderToBuffer(widget, size: const Size(30, 2));
      final s = buf.toPlainString();
      expect(s, contains('?'));
      expect(s, contains('Your name?'));
    });

    test('shows defaultValue between parentheses when value empty', () {
      final state = InputState();
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Port?',
        defaultValue: '8080',
        state: state,
      );
      final buf = renderToBuffer(widget, size: const Size(40, 2));
      expect(buf.toPlainString(), contains('(8080)'));
    });

    test('typing characters appends to value', () {
      final state = InputState();
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Name?',
        state: state,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(char: 'a'), ctx);
      widget.onKey(const KeyEvent(char: 'b'), ctx);
      widget.onKey(const KeyEvent(char: 'c'), ctx);
      expect(state.value, 'abc');
      expect(state.cursor, 3);
    });

    test('Enter triggers validate and sets error on failure', () {
      final state = InputState();
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Name?',
        state: state,
        validate: (v) => v.isEmpty ? 'Name required' : null,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: NamedKey.enter), ctx);
      expect(state.error, 'Name required');
      expect(state.submitted, isFalse);
    });

    test('Enter with valid value submits and clears error', () {
      final state = InputState();
      var submitted = '';
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Name?',
        state: state,
        validate: (v) => v.isEmpty ? 'required' : null,
        onSubmit: (v) => submitted = v,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(char: 'a'), ctx);
      widget.onKey(const KeyEvent(char: 'b'), ctx);
      widget.onKey(const KeyEvent(key: NamedKey.enter), ctx);
      expect(state.submitted, isTrue);
      expect(state.error, isNull);
      expect(submitted, 'ab');
    });

    test('typing after error clears the error', () {
      final state = InputState();
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Name?',
        state: state,
        validate: (v) => v.isEmpty ? 'required' : null,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: NamedKey.enter), ctx);
      expect(state.error, isNotNull);
      widget.onKey(const KeyEvent(char: 'a'), ctx);
      expect(state.error, isNull);
    });

    test('empty submit uses defaultValue', () {
      final state = InputState();
      var submitted = '';
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Port?',
        defaultValue: '8080',
        state: state,
        onSubmit: (v) => submitted = v,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(key: NamedKey.enter), ctx);
      expect(submitted, '8080');
      expect(state.submitted, isTrue);
    });

    test('lockOnSubmit:true makes widget skip further input', () {
      final state = InputState();
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Name?',
        state: state,
        lockOnSubmit: true,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(char: 'a'), ctx);
      widget.onKey(const KeyEvent(key: NamedKey.enter), ctx);
      expect(state.submitted, isTrue);
      expect(widget.isSkipped, isTrue);
      // Further keys are ignored
      widget.onKey(const KeyEvent(char: 'b'), ctx);
      expect(state.value, 'a');
    });

    test('lockOnSubmit:false stays editable after submit', () {
      final state = InputState();
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Name?',
        state: state,
        lockOnSubmit: false,
      );
      final ctx = _ctx();
      widget.onKey(const KeyEvent(char: 'a'), ctx);
      widget.onKey(const KeyEvent(key: NamedKey.enter), ctx);
      expect(state.submitted, isTrue);
      expect(widget.isSkipped, isFalse);
      widget.onKey(const KeyEvent(char: 'b'), ctx);
      expect(state.value, 'ab');
      expect(state.submitted, isFalse); // editing resets submitted
    });

    test('obscure displays asterisks', () {
      final state = InputState(initialValue: 'secret');
      final widget = Input(
        id: Key.symbol(#i),
        message: 'Password?',
        obscure: true,
        state: state,
      );
      final buf = renderToBuffer(widget, size: const Size(30, 2));
      final s = buf.toPlainString();
      expect(s, contains('******'));
      expect(s, isNot(contains('secret')));
    });
  });
}

RenderContext _ctx() {
  final buffer = Buffer(const Size(40, 5));
  final focus = FocusController();
  return RenderContext(
    buffer: buffer,
    area: Rect(0, 0, 40, 5),
    theme: const ThemeData(),
    focus: focus,
    async_: AsyncRegistry(),
    logger: const SilentLogger(),
    requestRedraw: () {},
  );
}
