import Glibc
import SystemPackage

struct DirectoryReader {
    static func readDirectory(at path: String) throws -> [String] {
        guard let dir = opendir(path) else {
            let errString = String(cString: strerror(errno))
            throw LSError.cannotAccess(path, errString)
        }
        defer { closedir(dir) }

        var entries: [String] = []
        while let ent = readdir(dir) {
            var dName = ent.pointee.d_name
            let name = withUnsafeBytes(of: &dName) { rawPtr in
                String(cString: rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self))
            }
            entries.append(name)
        }
        return entries
    }
}
