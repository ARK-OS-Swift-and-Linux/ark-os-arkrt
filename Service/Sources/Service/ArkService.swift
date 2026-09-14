import ServiceLifecycle

public protocol ArkService: Service, Sendable {
    var name: String { get }
    func healthCheck() async -> Bool
}
