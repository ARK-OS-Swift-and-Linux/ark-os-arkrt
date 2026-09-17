import XCTest
import Foundation

final class lsTests: XCTestCase {
    
    // Helper to run the 'ls' executable
    func runLS(args: [String], currentDirectory: String? = nil) throws -> (status: Int32, stdout: String, stderr: String) {
        let process = Process()
        
        // Use swift package path
        // We find the compiled binary in .build/debug/ls relative to the package path
        let executableURL = URL(fileURLWithPath: "./.build/debug/ls")
        process.executableURL = executableURL
        process.arguments = args
        
        if let dir = currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
        }
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        
        return (process.terminationStatus, stdout, stderr)
    }

    func testBasicListing() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "hello".write(to: tempDir.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        try "world".write(to: tempDir.appendingPathComponent("b.txt"), atomically: true, encoding: .utf8)
        
        let result = try runLS(args: [tempDir.path])
        XCTAssertEqual(result.status, 0)
        XCTAssertTrue(result.stdout.contains("a.txt"))
        XCTAssertTrue(result.stdout.contains("b.txt"))
    }
    
    func testAllOption() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "hello".write(to: tempDir.appendingPathComponent(".hidden.txt"), atomically: true, encoding: .utf8)
        
        // Without -a, should not contain .hidden.txt
        let normalResult = try runLS(args: [tempDir.path])
        XCTAssertFalse(normalResult.stdout.contains(".hidden.txt"))
        
        // With -a, should contain .hidden.txt
        let allResult = try runLS(args: ["-a", tempDir.path])
        XCTAssertTrue(allResult.stdout.contains(".hidden.txt"))
    }

    func testLongFormat() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "hello".write(to: tempDir.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        
        let result = try runLS(args: ["-l", tempDir.path])
        XCTAssertEqual(result.status, 0)
        // Check for permission string "-rw-" and file size "5"
        XCTAssertTrue(result.stdout.contains("a.txt"))
        XCTAssertTrue(result.stdout.contains("-rw-"))
        XCTAssertTrue(result.stdout.contains("5"))
    }
    
    func testCommaSeparated() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "".write(to: tempDir.appendingPathComponent("x"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent("y"), atomically: true, encoding: .utf8)
        
        let result = try runLS(args: ["-m", tempDir.path])
        XCTAssertEqual(result.status, 0)
        XCTAssertTrue(result.stdout.contains("x, y") || result.stdout.contains("y, x"))
    }
    
    func testMultipleDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let dir1 = tempDir.appendingPathComponent("dir1")
        let dir2 = tempDir.appendingPathComponent("dir2")
        try FileManager.default.createDirectory(at: dir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "".write(to: dir1.appendingPathComponent("file1"), atomically: true, encoding: .utf8)
        try "".write(to: dir2.appendingPathComponent("file2"), atomically: true, encoding: .utf8)
        
        let result = try runLS(args: [dir1.path, dir2.path])
        XCTAssertEqual(result.status, 0)
        XCTAssertTrue(result.stdout.contains("\(dir1.path):"))
        XCTAssertTrue(result.stdout.contains("file1"))
        XCTAssertTrue(result.stdout.contains("\(dir2.path):"))
        XCTAssertTrue(result.stdout.contains("file2"))
    }
    
    func testColors() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "".write(to: tempDir.appendingPathComponent("test.swift"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: tempDir.appendingPathComponent("testDir"), withIntermediateDirectories: true)
        
        let process = Process()
        let executableURL = URL(fileURLWithPath: "./.build/debug/ls")
        process.executableURL = executableURL
        process.arguments = ["--color=always", tempDir.path]
        
        process.environment = [
            "LS_COLORS": "di=01;34:*.swift=01;36",
            "PATH": ProcessInfo.processInfo.environment["PATH"] ?? ""
        ]
        
        let outPipe = Pipe()
        process.standardOutput = outPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertTrue(stdout.contains("\u{001B}[01;36mtest.swift\u{001B}[0m"), "Swift file should be colored")
        XCTAssertTrue(stdout.contains("\u{001B}[01;34mtestDir\u{001B}[0m"), "Directory should be colored")
    }
}
