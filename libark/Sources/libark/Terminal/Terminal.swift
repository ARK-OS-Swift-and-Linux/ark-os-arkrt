import Glibc
import SystemPackage

public struct Terminal {
    public static var isTTY: Bool {
        return isatty(STDOUT_FILENO) == 1
    }
    
    public static func getWidth() -> Int {
        var w = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w) == 0 {
            return Int(w.ws_col)
        }
        return 80
    }
}
