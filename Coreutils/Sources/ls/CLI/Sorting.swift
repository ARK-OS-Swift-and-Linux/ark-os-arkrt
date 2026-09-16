struct Sorting {
    static func sort(_ files: [FileInfo], by options: LSOptions) -> [FileInfo] {
        var sorted = files
        
        if options.unsorted {
            return sorted
        }
        
        sorted.sort { a, b in
            if options.sortByTime {
                let aTime = options.useATime ? a.atime : (options.useCTime ? a.ctime : a.mtime)
                let bTime = options.useATime ? b.atime : (options.useCTime ? b.ctime : b.mtime)
                
                if aTime.tv_sec != bTime.tv_sec {
                    return aTime.tv_sec > bTime.tv_sec
                }
                if aTime.tv_nsec != bTime.tv_nsec {
                    return aTime.tv_nsec > bTime.tv_nsec
                }
            } else if options.sortBySize {
                if a.size != b.size {
                    return a.size > b.size
                }
            } else if options.sortByExtension {
                let aExt = a.name.split(separator: ".").last.map(String.init) ?? ""
                let bExt = b.name.split(separator: ".").last.map(String.init) ?? ""
                if aExt != bExt {
                    return aExt < bExt
                }
            }
            
            // Fallback to name
            return a.name.lowercased() < b.name.lowercased()
        }
        
        if options.reverse {
            sorted.reverse()
        }
        
        return sorted
    }
}
