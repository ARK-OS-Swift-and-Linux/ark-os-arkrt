import Foundation

public struct FileSystemCommands {
    
    // MARK: - Core Commands
    
    public static func runLS(args: [String], currentDirectory: String) {
        let fileManager = FileManager.default
        let targetDir = args.isEmpty ? currentDirectory : resolvePath(args[0], currentDirectory: currentDirectory)
        
        do {
            let items = try fileManager.contentsOfDirectory(atPath: targetDir)
            for item in items.sorted() {
                print(item)
            }
        } catch {
            print("ls: cannot access '\(targetDir)': \(error.localizedDescription)")
        }
    }
    
    public static func runCAT(args: [String], currentDirectory: String) {
        if args.isEmpty {
            print("cat: missing operand")
            return
        }
        
        for arg in args {
            let path = resolvePath(arg, currentDirectory: currentDirectory)
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                print(content, terminator: "")
            } catch {
                print("cat: \(arg): No such file or directory")
            }
        }
    }
    
    public static func runECHO(args: [String]) {
        print(args.joined(separator: " "))
    }
    
    public static func runPWD(currentDirectory: String) {
        print(currentDirectory)
    }
    
    public static func runCD(args: [String], currentDirectory: inout String) {
        let target = args.isEmpty ? "/" : args[0]
        let newDir = resolvePath(target, currentDirectory: currentDirectory)
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: newDir, isDirectory: &isDir) {
            if isDir.boolValue {
                currentDirectory = newDir
            } else {
                print("cd: \(target): Not a directory")
            }
        } else {
            print("cd: \(target): No such file or directory")
        }
    }
    
    public static func runCP(args: [String], currentDirectory: String) {
        guard args.count >= 2 else {
            print("cp: missing file operand")
            return
        }
        
        let source = resolvePath(args[0], currentDirectory: currentDirectory)
        let destination = resolvePath(args[1], currentDirectory: currentDirectory)
        
        do {
            if FileManager.default.fileExists(atPath: destination) {
                try FileManager.default.removeItem(atPath: destination)
            }
            try FileManager.default.copyItem(atPath: source, toPath: destination)
        } catch {
            print("cp: \(error.localizedDescription)")
        }
    }
    
    public static func runMV(args: [String], currentDirectory: String) {
        guard args.count >= 2 else {
            print("mv: missing file operand")
            return
        }
        
        let source = resolvePath(args[0], currentDirectory: currentDirectory)
        let destination = resolvePath(args[1], currentDirectory: currentDirectory)
        
        do {
            if FileManager.default.fileExists(atPath: destination) {
                try FileManager.default.removeItem(atPath: destination)
            }
            try FileManager.default.moveItem(atPath: source, toPath: destination)
        } catch {
            print("mv: \(error.localizedDescription)")
        }
    }
    
    public static func runRM(args: [String], currentDirectory: String) {
        guard !args.isEmpty else {
            print("rm: missing operand")
            return
        }
        
        for arg in args {
            let target = resolvePath(arg, currentDirectory: currentDirectory)
            do {
                try FileManager.default.removeItem(atPath: target)
            } catch {
                print("rm: cannot remove '\(arg)': \(error.localizedDescription)")
            }
        }
    }
    
    public static func runMKDIR(args: [String], currentDirectory: String) {
        guard !args.isEmpty else {
            print("mkdir: missing operand")
            return
        }
        
        for arg in args {
            let target = resolvePath(arg, currentDirectory: currentDirectory)
            do {
                try FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("mkdir: cannot create directory '\(arg)': \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    public static func resolvePath(_ path: String, currentDirectory: String) -> String {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path).standardized.path
        }
        
        let basePath = currentDirectory.hasSuffix("/") ? currentDirectory : currentDirectory + "/"
        let fullPath = basePath + path
        
        let url = URL(fileURLWithPath: fullPath)
        return url.standardized.path
    }
}
