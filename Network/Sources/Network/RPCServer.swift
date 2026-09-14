public final class RPCServer {
    nonisolated(unsafe) public static let shared = RPCServer()

    private init() {
    }

    public func start(port: Int) throws {
        // Implement gRPC server
    }
}
