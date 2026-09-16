struct LSParser {
    let options: LSOptions
    
    init(options: LSOptions) {
        self.options = options
    }
    
    func parse() throws {
        let targets = options.paths.isEmpty ? ["."] : options.paths
        
        var allOutputs: [String] = []
        for target in targets {
            let entries: [String]
            
            // Check if target is file or dir
            let targetInfo = try Metadata.statFile(path: target, followSymlinks: options.dereference)
            if targetInfo.fileType == .directory {
                entries = try DirectoryReader.readDirectory(at: target)
            } else {
                entries = [targetInfo.name]
            }
            
            // Filtering
            var filteredEntries = entries
            if !options.all && !options.almostAll {
                filteredEntries = filteredEntries.filter { !$0.hasPrefix(".") }
            } else if options.almostAll {
                filteredEntries = filteredEntries.filter { $0 != "." && $0 != ".." }
            }
            
            // Metadata lookup for Sorting & Formatting
            var files: [FileInfo] = []
            for entry in filteredEntries {
                let fullPath = targetInfo.fileType == .directory ? "\(target)/\(entry)" : target
                do {
                    let info = try Metadata.statFile(path: fullPath, followSymlinks: options.dereference)
                    files.append(info)
                } catch {
                    print(error)
                }
            }
            
            // Sorting
            let sorted = Sorting.sort(files, by: options)
            
            // Formatting
            let formatted = Formatting.format(sorted, options: options)
            
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
