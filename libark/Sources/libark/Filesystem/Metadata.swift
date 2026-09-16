import Glibc
import SystemPackage

public struct FileMetadata {
    private let _stat: stat
    
    public init(path: Path) throws {
        var st = stat()
        let ret = path._with_unsafe_c_string { p in
            return Syscall._execute_secure(sys_no: 4, ptr1: UnsafeRawPointer(p), ptr2: UnsafeRawPointer(withUnsafeMutablePointer(to: &st) { $0 }))
        }
        if ret != 0 {
            throw SystemError(errNo: Int32(errno))
        }
        self._stat = st
    }
    
    public var size: Int {
        return Int(_stat.st_size)
    }
    
    public var uid: UInt32 {
        return _stat.st_uid
    }
    
    public var gid: UInt32 {
        return _stat.st_gid
    }
    
    public var permissions: Permissions {
        return Permissions(rawValue: UInt16(_stat.st_mode & 0o7777))
    }
}
