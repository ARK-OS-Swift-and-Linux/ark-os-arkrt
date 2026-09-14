public struct RoutingTable {
    nonisolated(unsafe) public static let shared = RoutingTable()

    private init() {
    }

    public func addRoute(destination: String, gateway: String) throws {
        // Implement routing
    }
}
