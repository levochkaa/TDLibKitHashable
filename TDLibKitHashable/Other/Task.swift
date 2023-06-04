// Task.swift

import Foundation

extension Task where Failure == Error {
    static func main(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ operation: @escaping @MainActor () async throws -> Success
    ) {
        Task { @MainActor in
            try await operation()
        }
    }
}
