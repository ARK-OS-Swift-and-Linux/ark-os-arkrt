import Foundation

public struct ProcessCommands {
    
    public static func runExternalCommand(command: String, args: [String], currentDirectory: String) -> Int32 {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
        
        // Determine the full path to the executable
        // Basic PATH resolution
        let executablePath = resolveExecutable(command)
        if executablePath == nil {
            print("sash: command not found: \(command)")
            return 127
        }
        
        process.executableURL = URL(fileURLWithPath: executablePath!)
        process.arguments = args
        
        // Inherit standard I/O
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            print("sash: failed to execute '\(command)': \(error.localizedDescription)")
            return 1
        }
    }
    
    private static func resolveExecutable(_ command: String) -> String? {
        if command.hasPrefix("/") || command.hasPrefix("./") || command.hasPrefix("../") {
            return FileManager.default.fileExists(atPath: command) ? command : nil
        }
        
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin:/system/bin"
        let paths = pathEnv.split(separator: ":").map { String($0) }
        
        for path in paths {
            let fullPath = path + "/" + command
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue {
                return fullPath
            }
        }
        
        return nil
    }
}
