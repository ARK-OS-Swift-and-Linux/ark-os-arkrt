public final class DeviceManager {
    nonisolated(unsafe) public static let shared = DeviceManager()

    private init() {
    }

    public func openDevice(node: String) throws {
        // Implementation for device interaction
    }
}
