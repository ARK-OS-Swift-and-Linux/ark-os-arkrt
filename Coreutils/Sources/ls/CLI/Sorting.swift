import libark

struct Sorting {
    static func sort(_ files: [FileMetadata], by options: LSOptions) -> [FileMetadata] {
        var criteria: [SortCriteria] = []
        
        if options.unsorted {
            criteria = [.none]
        } else if options.sortByTime {
            if options.useATime {
                criteria.append(.atime)
            } else if options.useCTime {
                criteria.append(.ctime)
            } else {
                criteria.append(.mtime)
            }
            criteria.append(.name) // fallback
        } else if options.sortBySize {
            criteria.append(.size)
            criteria.append(.name) // fallback
        } else if options.sortByExtension {
            criteria.append(.extension)
            criteria.append(.name) // fallback
        } else if options.sortByVersion {
            criteria.append(.version)
        } else {
            criteria.append(.name)
        }
        
        let engine = SortEngine(criteria: criteria, reverse: options.reverse)
        return engine.sort(files)
    }
}
