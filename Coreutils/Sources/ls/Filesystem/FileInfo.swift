import Glibc

struct FileInfo {
    let name: String
    let path: String
    let fileType: FileType
    let size: Int
    let uid: uid_t
    let gid: gid_t
    let mode: mode_t
    let blocks: Int
    let inode: ino_t
    let atime: timespec
    let mtime: timespec
    let ctime: timespec
    let hardLinks: Int
    let majorDevice: Int
    let minorDevice: Int
    let symlinkTarget: String?
}
