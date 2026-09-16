import Glibc

struct Metadata {
    static func statFile(path: String, followSymlinks: Bool = false) throws -> FileInfo {
        var statbuf = stat()
        let ret = followSymlinks ? stat(path, &statbuf) : lstat(path, &statbuf)
        if ret != 0 {
            let errString = String(cString: strerror(errno))
            throw LSError.cannotAccess(path, errString)
        }
        
        let type: FileType
        let mode = statbuf.st_mode
        if (mode & S_IFMT) == S_IFREG { type = .regular }
        else if (mode & S_IFMT) == S_IFDIR { type = .directory }
        else if (mode & S_IFMT) == S_IFLNK { type = .symbolicLink }
        else if (mode & S_IFMT) == S_IFCHR { type = .characterDevice }
        else if (mode & S_IFMT) == S_IFBLK { type = .blockDevice }
        else if (mode & S_IFMT) == S_IFIFO { type = .fifo }
        else if (mode & S_IFMT) == S_IFSOCK { type = .socket }
        else { type = .unknown }
        
        var symlinkTarget: String? = nil
        if type == .symbolicLink {
            var buf = [CChar](repeating: 0, count: 1024)
            let len = readlink(path, &buf, buf.count - 1)
            if len != -1 {
                buf[len] = 0
                symlinkTarget = String(cString: buf)
            }
        }
        
        // Custom simple lastPathComponent
        let name: String
        if let lastSlash = path.lastIndex(of: "/") {
            let afterSlash = path.index(after: lastSlash)
            name = String(path[afterSlash...])
        } else {
            name = path
        }

        // dev_t is just a UInt64 on many Linuxes, we will just pass 0 for major/minor for now
        // to avoid platform specific gnu_dev_major/minor dependency
        return FileInfo(
            name: name.isEmpty ? path : name,
            path: path,
            fileType: type,
            size: Int(statbuf.st_size),
            uid: statbuf.st_uid,
            gid: statbuf.st_gid,
            mode: statbuf.st_mode,
            blocks: Int(statbuf.st_blocks),
            inode: statbuf.st_ino,
            atime: statbuf.st_atim,
            mtime: statbuf.st_mtim,
            ctime: statbuf.st_ctim,
            hardLinks: Int(statbuf.st_nlink),
            majorDevice: 0,
            minorDevice: 0,
            symlinkTarget: symlinkTarget
        )
    }
}
