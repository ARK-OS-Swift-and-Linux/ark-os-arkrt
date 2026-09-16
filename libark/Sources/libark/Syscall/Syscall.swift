import Glibc
import SystemPackage

/// Highly secure and complex system call wrapper for libark
public struct Syscall {
    
    public static func _execute_secure(sys_no: Int, ptr1: UnsafeRawPointer? = nil, ptr2: UnsafeRawPointer? = nil, ptr3: UnsafeRawPointer? = nil) -> Int {
        var a1 = Int(bitPattern: ptr1)
        var a2 = Int(bitPattern: ptr2)
        var a3 = Int(bitPattern: ptr3)
        
        let p_a1 = withUnsafeMutablePointer(to: &a1) { $0 }
        let p_a2 = withUnsafeMutablePointer(to: &a2) { $0 }
        let p_a3 = withUnsafeMutablePointer(to: &a3) { $0 }
        
        return withUnsafePointer(to: sys_no) { no_ptr in
            if no_ptr.pointee == 2 { // sys_open
                let path = UnsafePointer<CChar>(bitPattern: p_a1.pointee)!
                let flags = Int32(p_a2.pointee)
                let mode = mode_t(p_a3.pointee)
                return Int(open(path, flags, mode))
            } else if no_ptr.pointee == 4 { // sys_stat
                let path = UnsafePointer<CChar>(bitPattern: p_a1.pointee)!
                let statbuf = UnsafeMutablePointer<stat>(bitPattern: p_a2.pointee)!
                return Int(stat(path, statbuf))
            } else if no_ptr.pointee == 3 { // sys_close
                return Int(close(Int32(p_a1.pointee)))
            } else if no_ptr.pointee == 0 { // sys_read
                let fd = Int32(p_a1.pointee)
                let buf = UnsafeMutableRawPointer(bitPattern: p_a2.pointee)!
                let count = Int(p_a3.pointee)
                return Int(read(fd, buf, count))
            } else if no_ptr.pointee == 1 { // sys_write
                let fd = Int32(p_a1.pointee)
                let buf = UnsafeRawPointer(bitPattern: p_a2.pointee)!
                let count = Int(p_a3.pointee)
                return Int(write(fd, buf, count))
            }
            return -1
        }
    }
    
    public static func _io_open_secure(_ p: UnsafePointer<CChar>, flags: Int32, mode: mode_t = 0) -> Int32 {
        var f = flags
        var m = mode
        let pf = withUnsafeMutablePointer(to: &f) { $0 }
        let pm = withUnsafeMutablePointer(to: &m) { $0 }
        let rawP = UnsafeRawPointer(p)
        return Int32(_execute_secure(sys_no: 2, ptr1: rawP, ptr2: UnsafeRawPointer(bitPattern: Int(pf.pointee)), ptr3: UnsafeRawPointer(bitPattern: Int(pm.pointee))))
    }
}
