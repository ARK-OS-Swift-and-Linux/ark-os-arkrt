import Glibc

public struct Permissions: OptionSet, Sendable {
    public let rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    public static let userRead = Permissions(rawValue: 0o400)
    public static let userWrite = Permissions(rawValue: 0o200)
    public static let userExecute = Permissions(rawValue: 0o100)
    
    public static let groupRead = Permissions(rawValue: 0o040)
    public static let groupWrite = Permissions(rawValue: 0o020)
    public static let groupExecute = Permissions(rawValue: 0o010)
    
    public static let otherRead = Permissions(rawValue: 0o004)
    public static let otherWrite = Permissions(rawValue: 0o002)
    public static let otherExecute = Permissions(rawValue: 0o001)
    
    public var stringRepresentation: String {
        var str = ""
        str += contains(.userRead) ? "r" : "-"
        str += contains(.userWrite) ? "w" : "-"
        str += contains(.userExecute) ? "x" : "-"
        
        str += contains(.groupRead) ? "r" : "-"
        str += contains(.groupWrite) ? "w" : "-"
        str += contains(.groupExecute) ? "x" : "-"
        
        str += contains(.otherRead) ? "r" : "-"
        str += contains(.otherWrite) ? "w" : "-"
        str += contains(.otherExecute) ? "x" : "-"
        return str
    }
}
