/// Local mode flags
/// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_355.html#SEC364
enum LocalMode {
  echo(0x00000008),
  isig(0x00000080),
  icanon(0x00000100),
  iexten(0x00000400),
  tcsanow(0),
  vmin(16),
  vtime(17);

  final int value;
  const LocalMode(this.value);
}
