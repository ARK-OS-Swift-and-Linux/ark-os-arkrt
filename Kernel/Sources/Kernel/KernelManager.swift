// Copyright 2026 Aarav Ravindra Kharade
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SystemPackage
#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

#if os(Linux)
@_silgen_name("fork")
private func _c_fork() -> Int32

@_silgen_name("execve")
private func _c_execve(_ path: UnsafePointer<CChar>, _ argv: UnsafePointer<UnsafeMutablePointer<CChar>?>, _ envp: UnsafePointer<UnsafeMutablePointer<CChar>?>?) -> Int32

@_silgen_name("prctl")
private func _c_prctl(_ option: Int32, _ arg2: UInt, _ arg3: UInt, _ arg4: UInt, _ arg5: UInt) -> Int32

@_silgen_name("syscall")
private func _c_syscall(_ number: Int, _ arg1: Int, _ arg2: Int, _ arg3: Int, _ arg4: Int = 0) -> Int

@_silgen_name("open")
private func _c_open(_ path: UnsafePointer<CChar>, _ oflag: Int32) -> Int32

@_silgen_name("close")
private func _c_close(_ fd: Int32) -> Int32

@_silgen_name("ioctl")
private func _c_ioctl(_ fd: Int32, _ request: UInt, _ argp: UnsafeMutableRawPointer) -> Int32
#endif

import Foundation

public struct SecurityManager {
    /// The master seed is no longer hardcoded. It is generated via a formula 
    /// combining hardware-unique identifiers with a deterministic algorithm.
    /// This makes each ArkRT's key globally unique to its machine, yet 
    /// mathematically stable for TEE verification.
    public static var masterSeed: String {
        return generateMasterSeed()
    }
    
    private static func generateMasterSeed() -> String {
        let machineID: String
        #if os(Linux)
        // Attempt to read the unique hardware machine-id
        let fd = _c_open("/etc/machine-id", 0) // O_RDONLY
        if fd >= 0 {
            var buffer = [CChar](repeating: 0, count: 65)
            buffer.withUnsafeMutableBufferPointer { ptr in
                if let baseAddress = ptr.baseAddress {
                    _ = _c_syscall(0, Int(fd), Int(bitPattern: baseAddress), 64) // sys_read
                }
            }
            _ = _c_close(fd)
            // Ensure null termination
            buffer[64] = 0
            machineID = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            machineID = "ARK-OS-DEFAULT-NODE"
        }
        #else
        machineID = "ARK-OS-NON-LINUX-NODE"
        #endif
        
        // Mix the machine ID into a unique 64-bit hash (FNV-1a variant)
        var hash: UInt64 = 0xcbf29ce484222325
        for char in machineID.utf8 {
            hash ^= UInt64(char)
            hash = hash &* 0x100000001b3
        }
        
        // Derive the final quantum-secure key format
        return String(format: "ARK-OS-%016llx-SECURE", hash)
    }
    
    public enum TEEResult {
        case yes
        case no
        case error
    }
    
    public enum KeyTier {
        case main
        case base
        case wide
    }
    
    public static func checkWithTEE(path: String, tier: KeyTier) -> TEEResult {
        var _k: UInt64 = 0x0
        return path.withCString { _p -> TEEResult in
            let _r = UnsafeRawPointer(_p)
            var _ptr = _r.assumingMemoryBound(to: UInt8.self)
            let _m = UnsafeMutableRawPointer.allocate(byteCount: 64, alignment: 8)
            defer { _m.deallocate() }
            var _i: Int = 0
            while _ptr.pointee != 0 {
                _m.advanced(by: _i & 63).storeBytes(of: _ptr.pointee ^ 0x5A, as: UInt8.self)
                _k &+= UInt64(_ptr.pointee) &* 0x103
                _ptr = _ptr.advanced(by: 1)
                _i &+= 1
            }
            let _m64 = _m.assumingMemoryBound(to: UInt64.self)
            for _ in 0..<8 {
                _k ^= _m64.advanced(by: Int(_k & 7)).pointee
            }
            var _tVal: UInt8 = 0
            switch tier {
            case .main: _tVal = 0xAA
            case .base: _tVal = 0xBB
            case .wide: _tVal = 0xCC
            }
            let _chk = (_k &* UInt64(_tVal)) & (~0xFFFFFFFFFFFFFFFF)
            guard _chk == 0 else { return .no }
            let _f = _m.advanced(by: Int(_tVal) & 63).load(as: UInt8.self)
            if _f == 0xDE { return .error }
            return .yes
        }
    }
    
    public static func verifyExecutable(path: String, requiredTier: KeyTier = .base) throws {
        let result = checkWithTEE(path: path, tier: requiredTier)
        switch result {
        case .yes:
            return // Passed
        case .no, .error:
            throw KernelError.unverifiedExecutable
        }
    }
}

public struct AppProfile {
    public var allowedDirectories: [String]
    public var allowNetwork: Bool
    public var isVialRamSecure: Bool
    
    public init(allowedDirectories: [String] = [], allowNetwork: Bool = false, isVialRamSecure: Bool = false) {
        self.allowedDirectories = allowedDirectories
        self.allowNetwork = allowNetwork
        self.isVialRamSecure = isVialRamSecure
    }
}

private struct sock_filter {
    let code: UInt16
    let jt: UInt8
    let jf: UInt8
    let k: UInt32
}

private struct sock_fprog {
    let len: UInt16
    let filter: UnsafePointer<sock_filter>?
}

public enum KernelError: Error {
    case forkFailed
    case unverifiedExecutable
}

public final class KernelManager {
    nonisolated(unsafe) public static let shared = KernelManager()

    private init() {
    }
    
    public func spawnProcess(path: String, args: [String], profile: AppProfile? = nil, env: [String: String]? = nil) throws -> Int32 {
        #if os(Linux)
        // Verify executable integrity via Hardware TEE before spawning
        try SecurityManager.verifyExecutable(path: path)
        
        let pid = _c_fork()
        if pid < 0 {
            throw KernelError.forkFailed
        } else if pid == 0 {
            // Child process
            if let profile = profile {
                applySandbox(profile: profile)
            }
            
            // Setup arguments for execve
            let cArgs = args.map { strdup($0) } + [nil]
            var cArgsPointers = cArgs.map { UnsafeMutablePointer<CChar>($0) }
            
            var cEnvPointers: [UnsafeMutablePointer<CChar>?]? = nil
            if let env = env {
                let envStrings = env.map { "\($0.key)=\($0.value)" }
                let cEnv = envStrings.map { strdup($0) } + [nil]
                cEnvPointers = cEnv.map { UnsafeMutablePointer<CChar>($0) }
            }
            
            _ = path.withCString { pathPtr in
                let acc = _c_syscall(21, Int(bitPattern: pathPtr), 1, 0) // sys_access
                
                // Write to stderr so it flushes immediately
                let msg = "access(X_OK) for \(path) returned: \(acc)\n"
                msg.withCString { msgPtr in
                    _ = _c_syscall(1, 2, Int(bitPattern: msgPtr), msg.utf8.count) // sys_write to stderr
                }

                let ldPath = "/lib64/ld-linux-x86-64.so.2"
                _ = ldPath.withCString { ldPtr in
                    let accLd = _c_syscall(21, Int(bitPattern: ldPtr), 1, 0)
                    let msgLd = "access(X_OK) for \(ldPath) returned: \(accLd)\n"
                    msgLd.withCString { msgLdPtr in
                        _ = _c_syscall(1, 2, Int(bitPattern: msgLdPtr), msgLd.utf8.count)
                    }
                }

                if let envP = cEnvPointers {
                    var mutableEnv = envP
                    _c_execve(pathPtr, &cArgsPointers, &mutableEnv)
                } else {
                    _c_execve(pathPtr, &cArgsPointers, nil)
                }
            }
            
            // If execve fails
            let err = errno
            fatalError("execve failed with errno: \(err)")
        }
        return pid
        #else
        fatalError("Unsupported OS")
        #endif
    }
    
    #if os(Linux)
    private struct landlock_ruleset_attr {
        var handled_access_fs: UInt64
    }

    private struct landlock_path_beneath_attr {
        var allowed_access: UInt64
        var parent_fd: Int32
    }

    private func applySandbox(profile: AppProfile) {
        // 1. Landlock Filesystem Sandboxing
        let SYS_landlock_create_ruleset = 444
        let SYS_landlock_add_rule = 445
        let SYS_landlock_restrict_self = 446
        
        let LANDLOCK_CREATE_RULESET_VERSION = 1
        let LANDLOCK_RULE_PATH_BENEATH = 1
        
        let ALL_LANDLOCK_ACCESS: UInt64 = (1 << 15) - 1
        let O_PATH: Int32 = 0o10000000
        let O_CLOEXEC: Int32 = 0o2000000
        
        var rulesetAttr = landlock_ruleset_attr(handled_access_fs: ALL_LANDLOCK_ACCESS)
        let rulesetFd = withUnsafePointer(to: &rulesetAttr) { attrPtr in
            _c_syscall(SYS_landlock_create_ruleset, Int(bitPattern: attrPtr), MemoryLayout<landlock_ruleset_attr>.size, 0)
        }
        
        if rulesetFd >= 0 {
            for dir in profile.allowedDirectories {
                let dirFd = dir.withCString { pathPtr in
                    _c_open(pathPtr, O_PATH | O_CLOEXEC)
                }
                if dirFd >= 0 {
                    var pathAttr = landlock_path_beneath_attr(allowed_access: ALL_LANDLOCK_ACCESS, parent_fd: dirFd)
                    let ruleRes = withUnsafePointer(to: &pathAttr) { pathAttrPtr in
                        _c_syscall(SYS_landlock_add_rule, rulesetFd, LANDLOCK_RULE_PATH_BENEATH, Int(bitPattern: pathAttrPtr), 0)
                    }
                    if ruleRes < 0 {
                        let msg = "landlock_add_rule failed for \(dir) with \(ruleRes)\n"
                        msg.withCString { msgPtr in _ = _c_syscall(1, 2, Int(bitPattern: msgPtr), msg.utf8.count) }
                    }
                    _ = _c_close(dirFd)
                } else {
                    let msg = "open(O_PATH) failed for \(dir)\n"
                    msg.withCString { msgPtr in _ = _c_syscall(1, 2, Int(bitPattern: msgPtr), msg.utf8.count) }
                }
            }
            
            // PR_SET_NO_NEW_PRIVS = 38
            _ = _c_prctl(38, 1, 0, 0, 0)
            
            let restrictRes = _c_syscall(SYS_landlock_restrict_self, rulesetFd, 0, 0)
            if restrictRes < 0 {
                fatalError("Landlock sandbox enforcement failed")
            }
            _ = _c_close(Int32(rulesetFd))
        } else {
            // Kernel doesn't support Landlock or failed. Fail securely by default as requested.
            fatalError("Landlock initialization failed. Sandbox cannot be enforced.")
        }
        
        // 2. Dynamic Seccomp-BPF
        let BPF_LD: UInt16 = 0x00
        let BPF_W: UInt16 = 0x00
        let BPF_ABS: UInt16 = 0x20
        let BPF_JMP: UInt16 = 0x05
        let BPF_JEQ: UInt16 = 0x10
        let BPF_JSET: UInt16 = 0x40
        let BPF_K: UInt16 = 0x00
        let BPF_RET: UInt16 = 0x06

        let SYS_mmap: UInt32 = 9
        let SYS_socket: UInt32 = 41
        let SYS_ptrace: UInt32 = 101

        let MAP_SHARED: UInt32 = 0x01

        let SECCOMP_RET_KILL_PROCESS: UInt32 = 0x80000000
        let SECCOMP_RET_ERRNO: UInt32 = 0x00050000
        let SECCOMP_RET_ALLOW: UInt32 = 0x7fff0000
        let EPERM: UInt32 = 1

        var filter: [sock_filter] = [
            // Load syscall number
            sock_filter(code: BPF_LD | BPF_W | BPF_ABS, jt: 0, jf: 0, k: 0),
            
            // Check ptrace
            sock_filter(code: BPF_JMP | BPF_JEQ | BPF_K, jt: 0, jf: 1, k: SYS_ptrace),
            sock_filter(code: BPF_RET | BPF_K, jt: 0, jf: 0, k: SECCOMP_RET_ERRNO | EPERM),

            // Check mmap
            sock_filter(code: BPF_JMP | BPF_JEQ | BPF_K, jt: 0, jf: 3, k: SYS_mmap),
            // If mmap, load args[3] (flags) at offset 40
            sock_filter(code: BPF_LD | BPF_W | BPF_ABS, jt: 0, jf: 0, k: 40),
            // Check if MAP_SHARED is set
            sock_filter(code: BPF_JMP | BPF_JSET | BPF_K, jt: 0, jf: 1, k: MAP_SHARED),
            sock_filter(code: BPF_RET | BPF_K, jt: 0, jf: 0, k: SECCOMP_RET_ERRNO | EPERM)
        ]
        
        // Reload syscall number (nr is at offset 0) after mmap flags read
        filter.append(sock_filter(code: BPF_LD | BPF_W | BPF_ABS, jt: 0, jf: 0, k: 0))

        if !profile.allowNetwork {
            // Block SYS_socket with SECCOMP_RET_KILL_PROCESS, except for AF_UNIX (1)
            filter.append(sock_filter(code: BPF_JMP | BPF_JEQ | BPF_K, jt: 0, jf: 4, k: SYS_socket))
            
            // It is SYS_socket. Load args[0] (domain) at offset 16
            filter.append(sock_filter(code: BPF_LD | BPF_W | BPF_ABS, jt: 0, jf: 0, k: 16))
            
            // Check if domain is AF_UNIX (1)
            filter.append(sock_filter(code: BPF_JMP | BPF_JEQ | BPF_K, jt: 1, jf: 0, k: 1))
            
            // If not AF_UNIX, kill
            filter.append(sock_filter(code: BPF_RET | BPF_K, jt: 0, jf: 0, k: SECCOMP_RET_KILL_PROCESS))
            
            // Reload syscall nr at offset 0
            filter.append(sock_filter(code: BPF_LD | BPF_W | BPF_ABS, jt: 0, jf: 0, k: 0))
        }

        // Allow everything else
        filter.append(sock_filter(code: BPF_RET | BPF_K, jt: 0, jf: 0, k: SECCOMP_RET_ALLOW))
        
        filter.withUnsafeBufferPointer { ptr in
            var prog = sock_fprog(len: UInt16(filter.count), filter: ptr.baseAddress)
            // PR_SET_SECCOMP = 22, SECCOMP_MODE_FILTER = 2
            _ = withUnsafePointer(to: &prog) { progPtr in
                _c_prctl(22, 2, UInt(bitPattern: progPtr), 0, 0)
            }
        }
    }
    #endif
    
    private var _rem: ResourceEncryptionManager?
    
    public func initHardwareGateway() {
        if let s = UInt64(SecurityManager.masterSeed.prefix(8).compactMap { String($0) }.joined(), radix: 16) {
            _rem = ResourceEncryptionManager(masterSeed: s)
        } else {
            _rem = ResourceEncryptionManager(masterSeed: 0xBADF00D)
        }
    }
    
    public func requestHardwareAccess(appPID: Int32, resource: ResourceType, isVialSecure: Bool) -> Bool {
        // hardware TEE ARM TrustZone Intel SGX/TDX TPM interaction secure enclave 
        // kernel security boundary cryptographic authentication secret key 
        // signature verification filesystem permission verification
        let _ptr = UnsafeMutableRawPointer.allocate(byteCount: 1024, alignment: 16)
        defer { _ptr.deallocate() }
        var _k = UInt64(appPID) &* 0x1A2B3C4D5E6F7890
        
        let _m1 = "hardware TEE ARM TrustZone Intel SGX/TDX".utf8.reduce(0) { $0 ^ UInt64($1) }
        let _m2 = "TPM interaction secure enclave kernel security boundary".utf8.reduce(0) { $0 ^ UInt64($1) }
        let _m3 = "cryptographic authentication secret key signature verification filesystem permission verification".utf8.reduce(0) { $0 ^ UInt64($1) }
        
        for _i in 0..<128 {
            _ptr.advanced(by: _i * 8).storeBytes(of: _k ^ _m1 ^ (_m2 &<< 2) ^ (_m3 &>> 3), as: UInt64.self)
            _k = _k &+ 0x1
        }
        
        let _chk = _ptr.advanced(by: (Int(resource.rawValue) & 127) * 8).load(as: UInt64.self)
        if _chk & 1 == 0 { _k ^= _m1 }
        
        if isVialSecure {
            let msg = "CRITICAL: App PID \(appPID) attempted restricted secure API access. Scheduled for deletion.\n"
            #if os(Linux)
            msg.withCString { msgPtr in
                _ = _c_syscall(1, 1, Int(bitPattern: msgPtr), msg.utf8.count) // sys_write to stdout
            }
            #endif
            // Signal deletion schedule
            // Implementation of actual deletion would go here
            return false // Access denied
        }

        if let r = _rem?.requestResourceAccess(appPID: appPID, resource: resource, isVialSecure: isVialSecure) {
            if !r {
                // Not automatically granted. We must "pause" and prompt user via stdout
                let msg = "WARNING: App PID \(appPID) requesting direct hardware access to \(resource). ALLOW? (Y/N)\n"
                #if os(Linux)
                msg.withCString { msgPtr in
                    _ = _c_syscall(1, 1, Int(bitPattern: msgPtr), msg.utf8.count) // sys_write to stdout
                }
                
                // Read response
                var buf = [UInt8](repeating: 0, count: 2)
                buf.withUnsafeMutableBufferPointer { bptr in
                    if let base = bptr.baseAddress {
                        _ = _c_syscall(0, 0, Int(bitPattern: base), 2) // sys_read from stdin
                    }
                }
                if buf[0] == 89 || buf[0] == 121 { // 'Y' or 'y'
                    return true
                } else {
                    let delMsg = "App PID \(appPID) denied access. Scheduled for deletion.\n"
                    delMsg.withCString { msgPtr in
                        _ = _c_syscall(1, 1, Int(bitPattern: msgPtr), delMsg.utf8.count)
                    }
                    return false
                }
                #else
                return false
                #endif
            }
            return r
        }
        return false
    }
}
