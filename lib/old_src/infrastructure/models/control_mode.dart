/// Control Modes
/// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_354.html#SEC363
enum ControlMode {
  csize(0x00000300),
  cs8(0x00000300);

  final int value;
  const ControlMode(this.value);
}
