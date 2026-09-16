import Foundation

enum LSError: Error, CustomStringConvertible {
    case cannotAccess(String, String)
    case generalError(String)
    
    var description: String {
        switch self {
        case .cannotAccess(let path, let reason):
            return "ls: cannot access '\(path)': \(reason)"
        case .generalError(let message):
            return "ls: \(message)"
        }
    }
}
