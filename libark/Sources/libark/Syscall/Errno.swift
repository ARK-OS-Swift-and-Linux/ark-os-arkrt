import Glibc

public struct SystemError: Error, CustomStringConvertible {
    public let errNo: Int32
    
    public init(errNo: Int32) {
        self.errNo = errNo
    }
    
    public var description: String {
        return String(cString: strerror(errNo))
    }
}
