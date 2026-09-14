public final class NetworkManager {
    nonisolated(unsafe) public static let shared = NetworkManager()
    private init() {}
    public func start() throws {
        // Startup logic for network
    }
}
