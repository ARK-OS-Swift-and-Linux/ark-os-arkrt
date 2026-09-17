import Foundation
import libark

struct LSColors {
    var codes: [String: String] = [:]
    
    init(envString: String) {
        let parts = envString.split(separator: ":")
        for part in parts {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                codes[String(kv[0])] = String(kv[1])
            }
        }
    }
    
    static func defaultColors() -> LSColors {
        if let env = ProcessInfo.processInfo.environment["LS_COLORS"] {
            return LSColors(envString: env)
        }
        return LSColors(envString: "")
    }
    
    func color(for file: FileMetadata) -> String {
        var key = ""
        
        switch file.fileType {
        case .directory:
            key = "di"
        case .symbolicLink:
            key = "ln"
        case .socket:
            key = "so"
        case .fifo:
            key = "pi"
        case .blockDevice:
            key = "bd"
        case .characterDevice:
            key = "cd"
        case .regular:
            if (file.mode & 0o111) != 0 {
                key = "ex"
            }
        default:
            break
        }
        
        var code = codes[key]
        
        // Check extensions if no specific type match or if it's a regular file that is not executable
        if code == nil || (file.fileType == .regular && (file.mode & 0o111) == 0) {
            let name = file.path.filename ?? file.path.string
            if let extIndex = name.lastIndex(of: ".") {
                let ext = String(name[extIndex...])
                if let extCode = codes["*" + ext] {
                    code = extCode
                }
            }
        }
        
        if let code = code {
            return "\u{001B}[\(code)m"
        }
        
        return "" // No color
    }
    
    func resetCode() -> String {
        return "\u{001B}[0m"
    }
    
    func format(name: String, for file: FileMetadata) -> String {
        let colorCode = color(for: file)
        if colorCode.isEmpty {
            return name
        }
        return "\(colorCode)\(name)\(resetCode())"
    }
}
