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

#if os(Linux)
@_silgen_name("memfd_create")
private func _c_memfd_create(_ name: UnsafePointer<CChar>, _ flags: UInt32) -> Int32

@_silgen_name("ftruncate")
private func _c_ftruncate(_ fd: Int32, _ length: Int) -> Int32

@_silgen_name("close")
private func _c_close(_ fd: Int32) -> Int32
#endif

public enum IPCError: Error {
    case memfdCreateFailed
    case truncateFailed
}

public final class IPC {
    nonisolated(unsafe) public static let shared = IPC()

    private init() {
    }

    public func sendMessage(to service: String, payload: [UInt8]) throws {
        // Implementation for IPC
    }

    /// Allocates an anonymous memory file (memfd) and sizes it.
    /// This enforces a zero-copy pipeline between apps, saving RAM.
    /// - Parameters:
    ///   - name: The debugging name for the memfd region.
    ///   - size: The size of the shared buffer in bytes.
    /// - Returns: The file descriptor to the anonymous memory region.
    public func createZeroCopyBuffer(name: String, size: Int) throws -> Int32 {
        #if os(Linux)
        let fd = name.withCString { cString in
            _c_memfd_create(cString, 0)
        }
        guard fd >= 0 else {
            throw IPCError.memfdCreateFailed
        }
        
        let ret = _c_ftruncate(fd, size)
        guard ret == 0 else {
            _ = _c_close(fd)
            throw IPCError.truncateFailed
        }
        
        return fd
        #else
        fatalError("memfd_create is only supported on Linux")
        #endif
    }
}
