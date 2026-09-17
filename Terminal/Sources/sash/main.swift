import Foundation

func printPrompt(currentDirectory: String) {
    let prompt = "sash \(currentDirectory) $ "
    if let data = prompt.data(using: .utf8) {
        FileHandle.standardOutput.write(data)
    }
}

func parseCommand(_ input: String) -> [String] {
    // Very basic parsing for Phase 1. Does not handle quotes properly yet.
    return input.split(separator: " ").map { String($0) }
}

var currentDirectory = FileManager.default.currentDirectoryPath

print("Welcome to sash (Swift Ark Shell) v0.1")

while true {
    printPrompt(currentDirectory: currentDirectory)
    
    guard let input = readLine() else {
        print()
        break
    }
    
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        continue
    }
    
    let parts = parseCommand(trimmed)
    guard let cmd = parts.first else { continue }
    let args = Array(parts.dropFirst())
    
    switch cmd {
    case "exit":
        exit(0)
    case "cd":
        FileSystemCommands.runCD(args: args, currentDirectory: &currentDirectory)
    case "pwd":
        FileSystemCommands.runPWD(currentDirectory: currentDirectory)
    case "cat":
        FileSystemCommands.runCAT(args: args, currentDirectory: currentDirectory)
    case "echo":
        FileSystemCommands.runECHO(args: args)
    case "cp":
        FileSystemCommands.runCP(args: args, currentDirectory: currentDirectory)
    case "mv":
        FileSystemCommands.runMV(args: args, currentDirectory: currentDirectory)
    case "rm":
        FileSystemCommands.runRM(args: args, currentDirectory: currentDirectory)
    case "mkdir":
        FileSystemCommands.runMKDIR(args: args, currentDirectory: currentDirectory)
    case "curl":
        NetworkingCommands.runCURL(args: args, currentDirectory: currentDirectory)
    case "wget":
        NetworkingCommands.runWGET(args: args, currentDirectory: currentDirectory)
    default:
        // Try to run as an external process
        _ = ProcessCommands.runExternalCommand(command: cmd, args: args, currentDirectory: currentDirectory)
    }
}
