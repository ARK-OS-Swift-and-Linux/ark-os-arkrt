import ServiceLifecycle
import Logging

public final class ServiceManager {
    nonisolated(unsafe) public static let shared = ServiceManager()
    private var services: [ArkService] = []
    
    private init() {}
    
    public func register(service: ArkService) {
        services.append(service)
    }
    
    public func startAll() async throws {
        var logger = Logger(label: "ArkRT.ServiceManager")
        logger.logLevel = .info
        
        // Use swift-service-lifecycle ServiceGroup for monitoring and lifecycle.
        // The gracefulShutdownSignals automatically handles SIGTERM and SIGINT.
        let group = ServiceGroup(
            services: services,
            gracefulShutdownSignals: [.sigterm, .sigint],
            logger: logger
        )
        
        try await group.run()
    }
}
