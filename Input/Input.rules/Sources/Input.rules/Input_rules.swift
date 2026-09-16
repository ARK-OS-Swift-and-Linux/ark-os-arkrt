import Foundation

/// Defines a rule for routing input to an application or system service.
public struct InputRule {
    public let devicePath: String
    public let allowedAppPID: Int32?
    public let requireFocus: Bool
    
    public init(devicePath: String, allowedAppPID: Int32? = nil, requireFocus: Bool = true) {
        self.devicePath = devicePath
        self.allowedAppPID = allowedAppPID
        self.requireFocus = requireFocus
    }
}

/// Defines an access permission for reading/writing input devices.
public struct InputPermission {
    public let appName: String
    public let canReadKeyboard: Bool
    public let canReadPointer: Bool
    public let canReadTouch: Bool
    
    public init(appName: String, canReadKeyboard: Bool, canReadPointer: Bool, canReadTouch: Bool) {
        self.appName = appName
        self.canReadKeyboard = canReadKeyboard
        self.canReadPointer = canReadPointer
        self.canReadTouch = canReadTouch
    }
}

public struct InputPolicyManager {
    nonisolated(unsafe) public static var activeRules: [InputRule] = []
    nonisolated(unsafe) public static var permissions: [String: InputPermission] = [:]
    
    public static func allowAccess(for appName: String, to deviceType: String) -> Bool {
        guard let permission = permissions[appName] else { return false }
        switch deviceType {
        case "keyboard": return permission.canReadKeyboard
        case "pointer": return permission.canReadPointer
        case "touch": return permission.canReadTouch
        default: return false
        }
    }
}
