import Foundation
#if canImport(Glibc)
import Glibc
#endif

// Constants for memfd and sealing if not defined in standard headers
private let _MFD_CLOEXEC: UInt32 = 0x0001
private let _MFD_ALLOW_SEALING: UInt32 = 0x0002
private let _F_ADD_SEALS: Int32 = 1033
private let _F_SEAL_SEAL: Int32 = 0x0001
private let _F_SEAL_SHRINK: Int32 = 0x0002
private let _F_SEAL_GROW: Int32 = 0x0004
private let _SYS_memfd_create = 319 // x86_64, use 279 for arm64 if needed

#if os(Linux)
@_silgen_name("syscall")
func _c_syscall_memfd_create(_ sysno: Int, _ name: UnsafePointer<CChar>, _ flags: UInt32) -> Int
#endif

public struct IPCPipeline {
    public let fd: Int32
    
    public init(name: String) throws {
        // Fallback to syscall if memfd_create is not exposed by Glibc
        let mfd = name.withCString { ptr in
            #if os(Linux)
            return _c_syscall_memfd_create(_SYS_memfd_create, ptr, _MFD_CLOEXEC | _MFD_ALLOW_SEALING)
            #else
            return -1
            #endif
        }
        if mfd < 0 {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        self.fd = Int32(mfd)
    }
    
    public func setSize(_ size: Int) throws {
        if ftruncate(fd, off_t(size)) != 0 {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }
    
    public func seal() throws {
        // Prevent shrinking, growing, and further sealing
        let seals = _F_SEAL_SHRINK | _F_SEAL_GROW | _F_SEAL_SEAL
        if fcntl(fd, _F_ADD_SEALS, seals) != 0 {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }
    
    public func closePipeline() {
        close(fd)
    }
}
