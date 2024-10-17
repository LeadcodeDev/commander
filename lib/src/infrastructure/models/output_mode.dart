/// Output Modes
/// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_353.html#SEC362
enum OutputMode {
  opost(0x00000001);

  final int value;
  const OutputMode(this.value);
}
