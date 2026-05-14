/// Commander TUI — declarative terminal user interface framework.
library;

export 'src/tui/geometry/rect.dart';
export 'src/tui/geometry/size.dart';

export 'src/tui/style/color.dart';
export 'src/tui/style/style.dart';
export 'src/tui/style/border.dart';

export 'src/tui/rendering/buffer.dart';
export 'src/tui/rendering/cell.dart' show charWidth;

export 'src/tui/layout/constraint.dart';
export 'src/tui/layout/layout.dart';

export 'src/tui/runtime/key.dart';
export 'src/tui/runtime/event.dart';
export 'src/tui/runtime/logger.dart';
export 'src/tui/runtime/render_context.dart';
export 'src/tui/runtime/focus_controller.dart' show FocusController;
export 'src/tui/runtime/async_registry.dart' show AsyncStatus, AsyncRegistry;
export 'src/tui/runtime/render_mode.dart';
export 'src/tui/runtime/run_terminal.dart';
export 'src/tui/runtime/not_a_terminal_exception.dart';
export 'src/tui/runtime/events_helpers.dart';

export 'src/tui/theme/theme_data.dart';

export 'src/tui/terminal/terminal.dart';

export 'src/tui/widget/widget.dart';

export 'src/tui/widgets/display/text.dart';
export 'src/tui/widgets/display/paragraph.dart';
export 'src/tui/widgets/display/block.dart';
export 'src/tui/widgets/display/container.dart';
export 'src/tui/widgets/display/padding.dart';
export 'src/tui/widgets/display/spacer.dart';
export 'src/tui/widgets/display/divider.dart';
export 'src/tui/widgets/display/each.dart';
export 'src/tui/widgets/display/row_column.dart';
export 'src/tui/widgets/display/stack.dart';
export 'src/tui/widgets/display/focusable.dart';
export 'src/tui/widgets/display/screen.dart';
export 'src/tui/widgets/display/scroll_view.dart';
export 'src/tui/widgets/display/code_block.dart';

export 'src/tui/widgets/input/text_field.dart';
export 'src/tui/widgets/input/input.dart';
export 'src/tui/widgets/input/input_number.dart';
export 'src/tui/widgets/input/checkbox.dart';
export 'src/tui/widgets/input/checkbox_group.dart';
export 'src/tui/widgets/input/button.dart';
export 'src/tui/widgets/input/radio_group.dart';
export 'src/tui/widgets/input/switch.dart';
export 'src/tui/widgets/input/slider.dart';
export 'src/tui/widgets/input/range.dart';
export 'src/tui/widgets/input/date_picker.dart';
export 'src/tui/widgets/input/time_picker.dart';
export 'src/tui/widgets/input/text_area.dart';

export 'src/tui/widgets/list/list_view.dart';
export 'src/tui/widgets/list/table.dart';
export 'src/tui/widgets/list/legacy_table.dart';
export 'src/tui/widgets/list/dropdown.dart';
export 'src/tui/widgets/list/select.dart';
export 'src/tui/widgets/list/tabs.dart';
export 'src/tui/widgets/list/tree.dart';

export 'src/tui/widgets/feedback/progress_bar.dart';
export 'src/tui/widgets/feedback/spinner.dart';
export 'src/tui/widgets/feedback/gauge.dart';

export 'src/tui/widgets/charts/sparkline.dart';
export 'src/tui/widgets/charts/bar_chart.dart';

export 'src/tui/widgets/async/async.dart';

export 'src/tui/widgets/chain/chain.dart';

export 'src/tui/navigation/navigator.dart';

export 'src/tui/utils/result.dart';

export 'src/tui/testing/test_terminal.dart';
export 'src/tui/testing/render_to_buffer.dart';
