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

import Crypto
import Foundation

public struct SignatureVault {
    // The Ed25519 public key (Master Keychain)
    // Used to verify that binaries were signed by the ArkOS distribution authority.
    nonisolated(unsafe) public static var masterPublicKeyBase64: String = ""
    
    // Internal Trusted Software Environment
    // Keys are paths, Values are Base64 Ed25519 signatures
    nonisolated(unsafe) public static var signatureRegistry: [String: String] = [:]

    public static func load(from path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let masterKey = json["masterPublicKeyBase64"] as? String {
                self.masterPublicKeyBase64 = masterKey
            }
            if let registry = json["signatureRegistry"] as? [String: String] {
                self.signatureRegistry = registry
            }
        }
    }
}

private struct fsverity_digest_sha256 {
    var digest_algorithm: UInt16
    var digest_size: UInt16
    var digest: (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )
}

public struct AppProfile {
    public var allowedDirectories: [String]
    public var allowNetwork: Bool
    
    public init(allowedDirectories: [String] = [], allowNetwork: Bool = false) {
        self.allowedDirectories = allowedDirectories
        self.allowNetwork = allowNetwork
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
    
    #if os(Linux)
    private func verifyExecutable(path: String) throws {
        // 1. Open the file
        let fd = path.withCString { pathPtr in
            _c_open(pathPtr, 0) // O_RDONLY
        }
        guard fd >= 0 else { throw KernelError.unverifiedExecutable }
        defer { _ = _c_close(fd) }

        // 2. Query fs-verity digest
        let FS_IOC_MEASURE_VERITY: UInt = 0xc0046686
        var digest = fsverity_digest_sha256(
            digest_algorithm: 0,
            digest_size: 32,
            digest: (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        )
        
        let ioctlRes = withUnsafeMutablePointer(to: &digest) { ptr in
            _c_ioctl(fd, FS_IOC_MEASURE_VERITY, UnsafeMutableRawPointer(ptr))
        }
        
        var hashBytes = [UInt8]()
        
        if ioctlRes == 0 {
            // 3. Extract SHA256 digest bytes
            withUnsafePointer(to: &digest.digest) { tuplePtr in
                let ptr = UnsafeRawPointer(tuplePtr).assumingMemoryBound(to: UInt8.self)
                hashBytes = Array(UnsafeBufferPointer(start: ptr, count: 32))
            }
        } else {
            // Polyfill: Compute SHA256 manually in user-space if fs-verity is unsupported (e.g., initramfs)
            let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
            let sha256 = SHA256.hash(data: fileData)
            hashBytes = Array(sha256)
        }
        
        // 4. Retrieve signature from the trusted SignatureVault
        guard let b64Signature = SignatureVault.signatureRegistry[path],
              let signatureData = Data(base64Encoded: b64Signature) else {
            throw KernelError.unverifiedExecutable
        }
        
        // 5. Verify using swift-crypto (Curve25519)
        guard let pubKeyData = Data(base64Encoded: SignatureVault.masterPublicKeyBase64) else {
            throw KernelError.unverifiedExecutable
        }
        
        do {
            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: pubKeyData)
            if !publicKey.isValidSignature(signatureData, for: hashBytes) {
                throw KernelError.unverifiedExecutable
            }
        } catch {
            throw KernelError.unverifiedExecutable
        }
    }
    #endif

    public func spawnProcess(path: String, args: [String], profile: AppProfile? = nil, env: [String: String]? = nil) throws -> Int32 {
        #if os(Linux)
        // Verify executable integrity using fs-verity before spawning
        try verifyExecutable(path: path)
        
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
            // Block SYS_socket with SECCOMP_RET_KILL_PROCESS
            filter.append(sock_filter(code: BPF_JMP | BPF_JEQ | BPF_K, jt: 0, jf: 1, k: SYS_socket))
            filter.append(sock_filter(code: BPF_RET | BPF_K, jt: 0, jf: 0, k: SECCOMP_RET_KILL_PROCESS))
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
}
