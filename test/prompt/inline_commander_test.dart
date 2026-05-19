import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commander_ui/prompt.dart';
import 'package:commander_ui/tui.dart';
import 'package:test/test.dart';

/// Drives events into [term] with a short pause between each, giving
/// `runTerminal` enough microtasks to complete setup and dispatch the
/// previous event before the next one is injected.
Future<void> _drive(TestTerminal term, List<Event> events) async {
  // Let runTerminal complete setup (a couple of queryCursorPosition awaits).
  await Future<void>.delayed(const Duration(milliseconds: 5));
  for (final e in events) {
    term.inject(e);
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('InlineCommander.ask', () {
    test('returns the submitted value', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.ask('Name?');
      await _drive(term, const [
        KeyEvent(char: 'a'),
        KeyEvent(char: 'b'),
        KeyEvent(key: NamedKey.enter),
      ]);
      expect(await future, 'ab');
    });

    test('rejects then accepts on validation', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.ask(
        'Name?',
        validate: (v) => v.length < 2 ? 'too short' : null,
      );
      await _drive(term, const [
        KeyEvent(char: 'a'),
        KeyEvent(key: NamedKey.enter), // rejected
        KeyEvent(char: 'b'),
        KeyEvent(key: NamedKey.enter), // accepted
      ]);
      expect(await future, 'ab');
    });

    test('uses defaultValue on empty submit', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.ask('Port?', defaultValue: '8080');
      await _drive(term, const [KeyEvent(key: NamedKey.enter)]);
      expect(await future, '8080');
    });

    test('Ctrl-C throws PromptCancelledException', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.ask('Name?');
      // Register the expectation before driving the cancel event so the
      // thrown PromptCancelledException is captured instead of being
      // surfaced as an unhandled async error.
      final expectation = expectLater(
        future,
        throwsA(isA<PromptCancelledException>()),
      );
      await _drive(term, const [KeyEvent(char: 'c', ctrl: true)]);
      await expectation;
    });
  });

  group('InlineCommander.password', () {
    test('obscures the rendered value', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.password('Pass?');
      await _drive(term, const [
        KeyEvent(char: 's'),
        KeyEvent(char: 'e'),
        KeyEvent(char: 'c'),
        KeyEvent(key: NamedKey.enter),
      ]);
      expect(await future, 'sec');
      // The plaintext characters must never appear in the rendered output.
      expect(term.output, isNot(contains('sec')));
    });
  });

  group('InlineCommander.number', () {
    test('parses digits within bounds', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.number('Age?', min: 0, max: 150);
      await _drive(term, const [
        KeyEvent(char: '4'),
        KeyEvent(char: '2'),
        KeyEvent(key: NamedKey.enter),
      ]);
      expect(await future, 42);
    });

    test('uses defaultValue on empty submit', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.number('Port?', defaultValue: 8080);
      await _drive(term, const [KeyEvent(key: NamedKey.enter)]);
      expect(await future, 8080);
    });
  });

  group('InlineCommander.select', () {
    test('returns the active item on Enter', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.select<String>(
        'Pick',
        options: const ['red', 'green', 'blue'],
      );
      await _drive(term, const [
        KeyEvent(key: NamedKey.arrowDown),
        KeyEvent(key: NamedKey.arrowDown),
        KeyEvent(key: NamedKey.enter),
      ]);
      expect(await future, 'blue');
    });

    test('honours defaultValue', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.select<String>(
        'Pick',
        options: const ['red', 'green', 'blue'],
        defaultValue: 'green',
      );
      await _drive(term, const [KeyEvent(key: NamedKey.enter)]);
      expect(await future, 'green');
    });

    test('throws on empty options', () {
      final commander = InlineCommander(allowNonInteractive: true);
      expect(
        () => commander.select<String>('?', options: const []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('InlineCommander.multiSelect', () {
    test('toggles items with space and submits with enter', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.multiSelect<String>(
        'Tools',
        options: const ['git', 'docker', 'make'],
      );
      await _drive(term, const [
        KeyEvent(char: ' '), // toggle git
        KeyEvent(key: NamedKey.arrowDown),
        KeyEvent(char: ' '), // toggle docker
        KeyEvent(key: NamedKey.enter),
      ]);
      expect(await future, ['git', 'docker']);
    });
  });

  group('InlineCommander.confirm', () {
    test("returns true on 'y'", () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.confirm('OK?');
      await _drive(term, const [KeyEvent(char: 'y')]);
      expect(await future, isTrue);
    });

    test("returns false on 'n'", () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.confirm('OK?', defaultValue: true);
      await _drive(term, const [KeyEvent(char: 'n')]);
      expect(await future, isFalse);
    });

    test('Enter uses defaultValue', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final future = commander.confirm('OK?', defaultValue: true);
      await _drive(term, const [KeyEvent(key: NamedKey.enter)]);
      expect(await future, isTrue);
    });
  });

  group('InlineCommander.task', () {
    test('returns the future value on success', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      final result = await commander.task('Loading', () async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return 42;
      });
      expect(result, 42);
    });

    test('propagates the thrown error', () async {
      final term = TestTerminal();
      final commander = InlineCommander(
        terminal: term,
        allowNonInteractive: true,
      );
      await expectLater(
        commander.task<void>('Loading', () async {
          throw StateError('boom');
        }),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('InlineCommander status helpers', () {
    test('success writes a green check and the message', () {
      final sink = _BufferSink();
      final commander = InlineCommander(sink: sink);
      commander.success('done');
      expect(sink.text, contains('✓'));
      expect(sink.text, contains('done'));
    });

    test('info, warn, error each emit their icon', () {
      final sink = _BufferSink();
      final commander = InlineCommander(sink: sink);
      commander.info('i');
      commander.warn('w');
      commander.error('e');
      expect(sink.text, contains('ℹ'));
      expect(sink.text, contains('!'));
      expect(sink.text, contains('✗'));
    });
  });

  group('InlineCommander chaining', () {
    test('two successive interactive calls each return their value', () async {
      // Each call gets a fresh TestTerminal because TestTerminal.shutdown()
      // closes its event stream — the TUI runtime always owns the terminal
      // lifecycle, so re-using one across prompts isn't supported.
      final term1 = TestTerminal();
      final c1 = InlineCommander(
        terminal: term1,
        allowNonInteractive: true,
      );
      final f1 = c1.ask('A?');
      await _drive(term1, const [
        KeyEvent(char: 'x'),
        KeyEvent(key: NamedKey.enter),
      ]);
      expect(await f1, 'x');

      final term2 = TestTerminal();
      final c2 = InlineCommander(
        terminal: term2,
        allowNonInteractive: true,
      );
      final f2 = c2.ask('B?');
      await _drive(term2, const [
        KeyEvent(char: 'y'),
        KeyEvent(key: NamedKey.enter),
      ]);
      expect(await f2, 'y');
    });
  });
}

class _BufferSink implements IOSink {
  final StringBuffer _b = StringBuffer();
  String get text => _b.toString();

  @override
  void write(Object? object) => _b.write(object);
  @override
  void writeln([Object? object = '']) => _b.writeln(object);
  @override
  void writeCharCode(int charCode) => _b.writeCharCode(charCode);
  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _b.writeAll(objects, separator);

  @override
  Encoding encoding = systemEncoding;
  @override
  void add(List<int> data) => _b.write(String.fromCharCodes(data));
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> flush() async {}
  @override
  Future<void> get done => Future<void>.value();
}
