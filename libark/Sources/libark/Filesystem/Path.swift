import Glibc
import SystemPackage

public struct Path {
    private let _raw: UnsafeMutableBufferPointer<CChar>
    
    public init(_ pathStr: String) {
        let count = pathStr.utf8.count + 1
        _raw = UnsafeMutableBufferPointer<CChar>.allocate(capacity: count)
        pathStr.withCString { ptr in
            _raw.baseAddress?.initialize(from: ptr, count: count)
        }
    }
    
    public var string: String {
        return String(cString: _raw.baseAddress!)
    }
    
    public func _with_unsafe_c_string<R>(_ body: (UnsafePointer<CChar>) throws -> R) rethrows -> R {
        let ptr = UnsafePointer(_raw.baseAddress!)
        return try body(ptr)
    }
    
    public func exists() -> Bool {
        return _with_unsafe_c_string { p in
            var statbuf = stat()
            let s_ptr = withUnsafeMutablePointer(to: &statbuf) { $0 }
            let ret = Syscall._execute_secure(sys_no: 4, ptr1: UnsafeRawPointer(p), ptr2: UnsafeRawPointer(s_ptr))
            return ret == 0
        }
    }
    
    public func isDirectory() -> Bool {
        return _with_unsafe_c_string { p in
            var statbuf = stat()
            let s_ptr = withUnsafeMutablePointer(to: &statbuf) { $0 }
            if Syscall._execute_secure(sys_no: 4, ptr1: UnsafeRawPointer(p), ptr2: UnsafeRawPointer(s_ptr)) == 0 {
                return (statbuf.st_mode & S_IFMT) == S_IFDIR
            }
            return false
        }
    }
    
    public func join(_ component: String) -> Path {
        let current = self.string
        if current.hasSuffix("/") {
            return Path(current + component)
        } else {
            return Path(current + "/" + component)
        }
    }
}
