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


import Kernel
import System
import Connect
import Service
import Terminal
import Glibc
import MMIO
import Logging
import ServiceLifecycle

// Declare mount if it's not automatically available
@_silgen_name("mount")
func c_mount(_ source: UnsafePointer<CChar>, _ target: UnsafePointer<CChar>, _ filesystemtype: UnsafePointer<CChar>, _ mountflags: UInt, _ data: UnsafeRawPointer?) -> Int32

@RegisterBlock
struct CPUConfigRegisters {
    @RegisterBlock(offset: 0x000)
    var control: Register<Control>
    
    @RegisterBlock(offset: 0x004)
    var interrupts: Register<Interrupts>
}

extension CPUConfigRegisters {
    @Register(bitWidth: 32)
    struct Control {
        @ReadWrite(bits: 0..<1, as: Bool.self)
        var enable: ENABLE
        
        @ReadWrite(bits: 1..<2, as: Bool.self)
        var reset: RESET
    }
    
    @Register(bitWidth: 32)
    struct Interrupts {
        @ReadWrite(bits: 0..<1, as: Bool.self)
        var globalEnable: GLOBAL_ENABLE
    }
}

// Core daemon definitions — each runs as a long-lived ServiceLifecycle service.

struct NetworkDaemon: ServiceLifecycle.Service {
    func run() async throws {
        print("[NetworkDaemon] Starting...")
        try? await Task.sleep(nanoseconds: 1_000_000_000_000)
    }
}

struct InputDaemon: ServiceLifecycle.Service {
    func run() async throws {
        print("[InputDaemon] Starting (xkbcommon)...")
        // Keeps running until graceful shutdown
        try? await Task.sleep(nanoseconds: 1_000_000_000_000)
    }
}

struct TaskManager: ServiceLifecycle.Service {
    func run() async throws {
        print("[TaskManager] Starting...")
        try? await Task.sleep(nanoseconds: 1_000_000_000_000)
    }
}

@main
struct Init {
    static func main() async {
        print("ArkOS Init Started")
        
        // Initialize all subsystems to ensure they are linked
        let _ = SystemPackage()
        let _ = NetworkSystem()
        let _ = ServiceSystem()
        let _ = TerminalSystem()
        
        // 1. Mount virtual filesystems
        print("Mounting /dev...")
        _ = c_mount("devtmpfs", "/dev", "devtmpfs", 0, nil)
        
        print("Mounting /proc...")
        _ = c_mount("proc", "/proc", "proc", 0, nil)
        
        print("Mounting /sys...")
        _ = c_mount("sysfs", "/sys", "sysfs", 0, nil)
        
        print("Mounting /run...")
        _ = c_mount("tmpfs", "/run", "tmpfs", 0, nil)
        
        print("System hardware initialized.")

        print("====== DRM DIAGNOSTICS ======")
        if let dir = opendir("/sys/class/drm") {
            while let ent = readdir(dir) {
                var dName = ent.pointee.d_name
                let name = withUnsafeBytes(of: &dName) { rawPtr in
                    String(cString: rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self))
                }
                if name != "." && name != ".." {
                    print("card: \(name)")
                    if let file = fopen("/sys/class/drm/\(name)/status", "r") {
                        var buf = [CChar](repeating: 0, count: 256)
                        if fgets(&buf, 256, file) != nil {
                            let statusStr = buf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
                            print("  status: \(statusStr.trimmingCharacters(in: .whitespacesAndNewlines))")
                        }
                        fclose(file)
                    }
                    
                    let modesPath = "/sys/class/drm/\(name)/modes"
                    if let file = fopen(modesPath, "r") {
                        var buf = [CChar](repeating: 0, count: 256)
                        while fgets(&buf, 256, file) != nil {
                            let modeStr = buf.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
                            print("    - \(modeStr.trimmingCharacters(in: .whitespacesAndNewlines))")
                        }
                        fclose(file)
                    }
                }
            }
            closedir(dir)
        }
        print("=============================")


        // 2. Switch standard IO to TTY display
        print("Switching IO to /dev/tty1...")
        let ttyFd = open("/dev/tty1", O_RDWR)
        if ttyFd >= 0 {
            dup2(ttyFd, 0)
            dup2(ttyFd, 1)
            dup2(ttyFd, 2)
            if ttyFd > 2 {
                close(ttyFd)
            }
        } else {
            print("Failed to open /dev/tty1")
        }
        
        print("Spawning sash shell on TTY...")
        do {
            let pid = try KernelManager.shared.spawnProcess(path: "/system/bin/sh", args: ["sh"])
            print("Spawned sash with PID \(pid)")
        } catch {
            print("Failed to spawn sash: \(error)")
        }

        // 3. Start Core Daemons via ServiceLifecycle
        print("Starting core daemons...")
        
        let networkDaemon = NetworkDaemon()
        let inputDaemon = InputDaemon()
        let securityDaemon = SecurityDaemon()
        let taskManager = TaskManager()
        let logger = Logger(label: "ArkRT.Init")
        
        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [
                    .init(service: networkDaemon),
                    .init(service: inputDaemon),
                    .init(service: securityDaemon),
                    .init(service: taskManager)
                ],
                gracefulShutdownSignals: [.sigterm, .sigint, .sigquit],
                cancellationSignals: [],
                logger: logger
            )
        )
        
        do {
            try await serviceGroup.run()
        } catch {
            print("ServiceGroup failed with error: \(error)")
        }
        
        print("ARK-OS Init Terminated.")
    }
}
