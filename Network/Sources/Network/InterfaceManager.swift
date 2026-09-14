public struct InterfaceManager {
    nonisolated(unsafe) public static let shared = InterfaceManager()

    private init() {
    }

    public func listInterfaces() -> [String] {
        return []
    }
}
