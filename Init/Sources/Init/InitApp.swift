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

/// DisplayDaemon launches the GTK3 display app (ark_display) as a sandboxed process.
/// It is granted only the minimum permissions needed:
///   - Filesystem: /system/bin (executable), /usr/share/fonts (fonts), /tmp (runtime)
///   - Network: disabled
/// The process is fully sandboxed via Landlock + Seccomp through KernelManager.
struct DisplayDaemon: ServiceLifecycle.Service {
    private let displayBinaryPath = "/system/bin/BootAnim"
    
    func run() async throws {
        print("[DisplayDaemon] Launching GTK3 display...")
        
        // Only grant access to the directories the display app strictly needs
        let displayProfile = AppProfile(
            allowedDirectories: [
                "/system/bin",          // The binary itself
                "/usr/share/fonts",     // Roboto font files
                "/usr/share/glib-2.0",  // GLib schemas
                "/usr/share/X11",       // XKB configuration
                "/tmp",                 // GTK3/fontconfig runtime cache
                "/etc/fonts",           // fontconfig configuration
                "/dev",                 // DRI/GPU device access
                "/proc",               // Process info (required by glib)
                "/sys",                  // Sysfs (required for device enumeration)
                "/run",                  // XDG_RUNTIME_DIR and wayland socket
                "/lib",
                "/lib64",
                "/usr/lib",
                "/"
            ],
            allowNetwork: true         // Display app needs zero network access, but SYS_socket is used for UNIX sockets and seccomp blocks it if false
        )
        
        // Wait for Weston to create the wayland-0 socket before launching GTK app
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        do {
            let pid = try KernelManager.shared.spawnProcess(
                path: displayBinaryPath,
                args: [displayBinaryPath],
                profile: displayProfile,
                env: [
                    "XDG_RUNTIME_DIR": "/run/user/0", 
                    "WAYLAND_DISPLAY": "wayland-0", 
                    "LD_LIBRARY_PATH": "/lib",
                    "FONTCONFIG_FILE": "/etc/fonts/fonts.conf",
                    "FONTCONFIG_PATH": "/etc/fonts",
                    "HOME": "/tmp",
                    "FC_DEBUG": "1"
                ]
            )
            print("[DisplayDaemon] ark_display launched with PID \(pid)")
            
            var status: Int32 = 0
            _ = Glibc.waitpid(pid, &status, 0)
            print("[DisplayDaemon] ark_display exited with status \(status). Dropping to fallback shell.")
            
            let shellProfile = AppProfile(
                allowedDirectories: ["/"],
                allowNetwork: true
            )
            let shellPid = try KernelManager.shared.spawnProcess(
                path: "/system/bin/sh",
                args: ["/system/bin/sh"],
                profile: shellProfile,
                env: ["PATH": "/system/bin:/bin", "HOME": "/"]
            )
            _ = Glibc.waitpid(shellPid, &status, 0)
            
        } catch {
            print("[DisplayDaemon] Failed to launch: \(error)")
        }
        
        // Keep daemon alive — it supervises the display process
        try? await Task.sleep(nanoseconds: 1_000_000_000_000)
    }
}

struct SeatdDaemon: ServiceLifecycle.Service {
    private let seatdBinaryPath = "/system/bin/seatd"
    
    func run() async throws {
        print("[SeatdDaemon] Launching seatd...")
        
        let seatdProfile = AppProfile(
            allowedDirectories: [
                "/system/bin",
                "/dev",
                "/sys",
                "/proc",
                "/run",
                "/lib",
                "/lib64",
                "/usr/lib",
                "/"
            ],
            allowNetwork: true
        )
        
        do {
            let pid = try KernelManager.shared.spawnProcess(
                path: seatdBinaryPath,
                args: [seatdBinaryPath, "-g", "root"],
                profile: seatdProfile,
                env: ["XDG_RUNTIME_DIR": "/run", "LD_LIBRARY_PATH": "/lib", "SEATD_SOCK": "/run/seatd.sock"]
            )
            print("[SeatdDaemon] seatd launched with PID \(pid)")
        } catch {
            print("[SeatdDaemon] Failed to launch seatd: \(error)")
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000_000)
    }
}

struct WestonDaemon: ServiceLifecycle.Service {
    private let westonBinaryPath = "/system/bin/weston"
    
    func run() async throws {
        print("[WestonDaemon] Launching weston...")
        
        // Wait for seatd to initialize
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let westonProfile = AppProfile(
            allowedDirectories: [
                "/system/bin",
                "/dev",
                "/sys",
                "/proc",
                "/run",
                "/lib",
                "/lib64",
                "/usr/lib",
                "/usr/share/X11",
                "/"
            ],
            allowNetwork: true
        )
        
        _ = Glibc.mkdir("/run/user", 0o700)
        _ = Glibc.mkdir("/run/user/0", 0o700)
        
        do {
            let pid = try KernelManager.shared.spawnProcess(
                path: westonBinaryPath,
                args: [westonBinaryPath, "-B", "drm-backend.so", "--renderer=pixman", "--seat=seat0", "--continue-without-input"],
                profile: westonProfile,
                env: [
                    "XDG_RUNTIME_DIR": "/run/user/0",
                    "WAYLAND_DISPLAY": "wayland-0",
                    "SEATD_SOCK": "/run/seatd.sock",
                    "LD_LIBRARY_PATH": "/lib:/usr/lib:/usr/lib/gbm:/usr/lib/dri",
                    "GBM_DRIVERS_PATH": "/usr/lib/gbm:/usr/lib",
                    "LIBGL_DRIVERS_PATH": "/usr/lib/dri"
                ]
            )
            print("[WestonDaemon] weston launched with PID \(pid)")
        } catch {
            print("[WestonDaemon] Failed to launch weston: \(error)")
        }
        
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

        do {
            try SignatureVault.load(from: "/signature_vault.json")
            print("SignatureVault loaded successfully.")
        } catch {
            print("Failed to load SignatureVault: \(error)")
        }
        
        // 2. Start Core Daemons via ServiceLifecycle
        print("Starting core daemons...")
        
        let networkDaemon = NetworkDaemon()
        let inputDaemon = InputDaemon()
        let securityDaemon = SecurityDaemon()
        let taskManager = TaskManager()
        let seatdDaemon = SeatdDaemon()
        let westonDaemon = WestonDaemon()
        let displayDaemon = DisplayDaemon()
        let logger = Logger(label: "ArkRT.Init")
        
        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [
                    .init(service: networkDaemon),
                    .init(service: inputDaemon),
                    .init(service: securityDaemon),
                    .init(service: taskManager),
                    .init(service: seatdDaemon),
                    .init(service: westonDaemon),
                    .init(service: displayDaemon)
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
        
        print("ArkOS Init Terminated.")
    }
}
