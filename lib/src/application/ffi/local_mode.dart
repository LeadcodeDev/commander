/// Local Modes
/// https://ftp.gnu.org/old-gnu/Manuals/glibc-2.2.3/html_node/libc_355.html#SEC364
final class LocalMode {
  static const int ECHO = 0x00000008;
  static const int ISIG = 0x00000080;
  static const int ICANON = 0x00000100;
  static const int IEXTEN = 0x00000400;
  static const int TCSANOW = 0;
  static const int VMIN = 16;
  static const int VTIME = 17;
}
