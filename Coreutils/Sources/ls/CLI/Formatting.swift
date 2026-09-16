struct Formatting {
    static func format(_ files: [FileInfo], options: LSOptions) -> [String] {
        var output: [String] = []
        
        if options.longFormat {
            // Need to compute max widths for alignment
            let sizes = files.map { String($0.size) }
            let links = files.map { String($0.hardLinks) }
            let maxSizeLen = sizes.map { $0.count }.max() ?? 0
            let maxLinksLen = links.map { $0.count }.max() ?? 0
            
            for file in files {
                let perms = formatPermissions(mode: file.mode, type: file.fileType)
                let linkStr = String(file.hardLinks).padding(toLength: maxLinksLen, withPad: " ", startingAt: 0)
                // In a full implementation, map uid/gid to names using getpwuid/getgrgid
                let uidStr = String(file.uid)
                let gidStr = String(file.gid)
                let sizeStr = String(file.size).padding(toLength: maxSizeLen, withPad: " ", startingAt: 0)
                // Simplified time
                let timeStr = "Time" // Would format timespec here
                
                var line = "\(perms) \(linkStr) \(uidStr) \(gidStr) \(sizeStr) \(timeStr) \(file.name)"
                if let target = file.symlinkTarget {
                    line += " -> \(target)"
                }
                output.append(line)
            }
        } else {
            // Simple single column or comma separated
            if options.commas {
                output = [files.map { $0.name }.joined(separator: ", ")]
            } else {
                output = files.map { $0.name }
            }
        }
        
        return output
    }
    
    static func formatPermissions(mode: UInt32, type: FileType) -> String {
        var str = ""
        switch type {
        case .directory: str += "d"
        case .symbolicLink: str += "l"
        case .characterDevice: str += "c"
        case .blockDevice: str += "b"
        case .fifo: str += "p"
        case .socket: str += "s"
        case .regular: fallthrough
        case .unknown: str += "-"
        }
        
        // Very basic perm mapping
        let rwx: [UInt32] = [0o400, 0o200, 0o100, 0o040, 0o020, 0o010, 0o004, 0o002, 0o001]
        let chars = ["r", "w", "x", "r", "w", "x", "r", "w", "x"]
        
        for i in 0..<9 {
            str += (mode & rwx[i]) != 0 ? chars[i] : "-"
        }
        
        return str
    }
}
