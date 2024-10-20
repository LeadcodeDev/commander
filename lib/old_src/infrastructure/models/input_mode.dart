/// Input Modes
/// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_352.html
enum InputMode {
  brkint(0x00000002),
  inpck(0x00000010),
  istrip(0x00000020),
  icrnl(0x00000100),
  ixon(0x00000200);

  final int value;
  const InputMode(this.value);
}
