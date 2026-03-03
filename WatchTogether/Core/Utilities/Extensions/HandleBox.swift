import Foundation

/// Wraps a non-Sendable reference in an @unchecked Sendable box so it can be
/// safely captured in Swift 6 @Sendable closures (e.g. AsyncStream.onTermination).
/// Use only for values that are inherently thread-safe despite lacking the annotation
/// (e.g. opaque Firebase listener handles that are just used for deregistration).
final class HandleBox: @unchecked Sendable {
    let value: any NSObjectProtocol
    init(_ value: any NSObjectProtocol) { self.value = value }
}
