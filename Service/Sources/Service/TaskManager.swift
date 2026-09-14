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

import Foundation
import ServiceLifecycle
#if canImport(Glibc)
import Glibc
#endif

public enum TaskState {
    case running
    case background
    case suspended
}

#if os(Linux)
@_silgen_name("syscall")
func _c_syscall(_ sysno: Int, _ arg1: Int, _ arg2: Int, _ arg3: Int, _ arg4: Int, _ arg5: Int) -> Int
#endif

public actor TaskManager: Service {
    private var tasks: [pid_t: TaskState] = [:]
    
    // MADV_PAGEOUT is 21 on Linux
    private let _MADV_PAGEOUT: Int32 = 21
    private let _SYS_pidfd_open = 434
    private let _SYS_process_madvise = 440
    
    public init() {}
    
    public func run() async throws {
        print("[TaskManager] Service started. Monitoring task states...")
        // Keeps the daemon running
        try await Task.sleep(nanoseconds: 1_000_000_000_000)
    }
    
    public func setTaskState(pid: pid_t, state: TaskState) {
        tasks[pid] = state
        
        if state == .background {
            compressMemory(for: pid)
        }
    }
    
    private func compressMemory(for pid: pid_t) {
        print("[TaskManager] Compressing memory for task \(pid) to save RAM...")
        
        #if os(Linux)
        let pidfd = _c_syscall(_SYS_pidfd_open, Int(pid), 0, 0, 0, 0)
        if pidfd >= 0 {
            // Parse /proc/[pid]/maps to find memory regions
            let mapsPath = "/proc/\(pid)/maps"
            if let mapsString = try? String(contentsOfFile: mapsPath, encoding: .utf8) {
                var iovecs: [iovec] = []
                for line in mapsString.split(separator: "\n") {
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    // We target private mappings (usually end with 'p' in permissions)
                    if parts.count >= 2, parts[1].hasSuffix("p") {
                        let addressPart = parts[0]
                        let addresses = addressPart.split(separator: "-")
                        if addresses.count == 2,
                           let start = UInt(addresses[0], radix: 16),
                           let end = UInt(addresses[1], radix: 16) {
                            let length = end - start
                            iovecs.append(iovec(iov_base: UnsafeMutableRawPointer(bitPattern: start), iov_len: Int(length)))
                        }
                    }
                }
                
                if !iovecs.isEmpty {
                    let count = iovecs.count
                    let sys = _SYS_process_madvise
                    let pageout = Int(_MADV_PAGEOUT)
                    let fd = Int(pidfd)
                    
                    let ret = iovecs.withUnsafeBufferPointer { iovecPtr -> Int in
                        return _c_syscall(sys, fd, Int(bitPattern: iovecPtr.baseAddress), count, pageout, 0)
                    }
                    if ret >= 0 {
                        print("[TaskManager] Issued MADV_PAGEOUT for task \(pid) via process_madvise to compress \(count) memory regions.")
                    } else {
                        print("[TaskManager] process_madvise failed for task \(pid) with errno \(errno).")
                    }
                }
            }
            
            close(Int32(pidfd))
        } else {
            print("[TaskManager] Failed to open pidfd for \(pid).")
        }
        #endif
    }
}
