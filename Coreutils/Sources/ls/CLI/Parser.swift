import libark

struct LSParser {
    let options: LSOptions
    
    init(options: LSOptions) {
        self.options = options
    }
    
    func parse() throws {
        var resolvedOptions = options
        if !resolvedOptions.longFormat && !resolvedOptions.onePerLine && !resolvedOptions.commas && !resolvedOptions.across {
            if Terminal.stdout.isTTY {
                resolvedOptions.columns = true
            } else {
                resolvedOptions.onePerLine = true
            }
        }

        let targets = resolvedOptions.paths.isEmpty ? ["."] : resolvedOptions.paths
        
        var allOutputs: [String] = []
        for target in targets {
            let entries: [String]
            
            // Check if target is file or dir
            let targetPath = Path(target)
            let targetInfo = resolvedOptions.dereference ? try FileMetadata.stat(path: targetPath) : try FileMetadata.lstat(path: targetPath)
            if targetInfo.fileType == .directory {
                let dir = try Directory.open(path: targetPath)
                entries = dir.map { $0.name }
            } else {
                entries = [targetInfo.path.filename ?? targetInfo.path.string]
            }
            
            // Filtering
            var filteredEntries = entries
            if !resolvedOptions.all && !resolvedOptions.almostAll {
                filteredEntries = filteredEntries.filter { !$0.hasPrefix(".") }
            } else if resolvedOptions.almostAll {
                filteredEntries = filteredEntries.filter { $0 != "." && $0 != ".." }
            }
            
            // Metadata lookup for Sorting & Formatting
            var files: [FileMetadata] = []
            for entry in filteredEntries {
                let fullPath = targetInfo.fileType == .directory ? Path("\(target)/\(entry)") : targetPath
                do {
                    let info = resolvedOptions.dereference ? try FileMetadata.stat(path: fullPath) : try FileMetadata.lstat(path: fullPath)
                    files.append(info)
                } catch {
                    print(error)
                }
            }
            
            // Sorting
            let sorted = Sorting.sort(files, by: resolvedOptions)
            
            // Formatting
            let formatted = Formatting.format(sorted, options: resolvedOptions)
            
            if targets.count > 1 && targetInfo.fileType == .directory {
                allOutputs.append("\(target):")
            }
            allOutputs.append(contentsOf: formatted)
        }
        
        for out in allOutputs {
            print(out)
        }
    }
}
