//
//  TaskQueue.swift
//  TaskQueue
//
//  Created by Kyle Hughes on 10/7/22.
//

import Foundation

/// An actor that can constrain the number of concurrent `Task`s being executed, like `OperationQueue` with
/// `maxConcurrentOperationCount`.
public actor TaskQueue {
    /// The maximum number of queued tasks that can run at the same time.
    ///
    /// The value in this property affects only the tasks that the current queue has executing at the same time. Other
    /// queues can also execute their maximum number of operations in parallel.
    public let maxConcurrentTaskCount: Int
    
    private var numberOfRunningTasks: Int
    private var pendingContinuations: [UnsafeContinuation<Void, Never>]
    
    // MARK: Public Initialization
    
    /// Create a new queue where the maximum number of concurrent tasks is equivalent to the maximum number of
    /// concurrent connections that the given `URLSession` can handle.
    ///
    /// We use `httpMaximumConnectionsPerHost` on the `URLSession`'s configuration as an approximation of this value.
    /// This has been observed anecdotally to be accurate.
    ///
    /// This is provided as a convenience for a common callsite. The queue does not need to be used with the given
    /// `URLSession` and the queue does not hold a reference to it.
    ///
    /// - Parameter urlSession: The `URLSession` that the queue will be tailored to.
    public init(for urlSession: URLSession) {
        self.init(maxConcurrentTaskCount: urlSession.configuration.httpMaximumConnectionsPerHost)
    }
    
    public init(maxConcurrentTaskCount: Int) {
        self.maxConcurrentTaskCount = maxConcurrentTaskCount
        
        numberOfRunningTasks = 0
        pendingContinuations = []
    }
    
    // MARK: Adding Interface

    @discardableResult
    public func add<Success>(
        priority: TaskPriority? = nil,
        _ task: @escaping @Sendable () async -> Success
    ) -> Task<Success, Never> {
        Task(priority: priority) {
            await add(task)
        }
    }
    
    @discardableResult
    public func add<Success>(
        priority: TaskPriority? = nil,
        _ task: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, any Error> {
        Task(priority: priority) {
            try await add(task)
        }
    }
    
    public func add<Success>(_ task: @escaping @Sendable () async throws -> Success) async rethrows -> Success {
        await setUpTask()
        
        defer {
            tearDownTask()
        }
        
        return try await task()
    }
    
    // MARK: Conditional Additing Interface
    
    @discardableResult
    public func addUnlessCancelled<Success>(
        priority: TaskPriority? = nil,
        _ task: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, any Error> {
        Task(priority: priority) {
            try await addUnlessCancelled(task)
        }
    }
    
    public func addUnlessCancelled<Success>(
        _ task: @escaping @Sendable () async throws -> Success
    ) async throws -> Success {
        try Task.checkCancellation()
        
        await setUpTask()
        
        defer {
            tearDownTask()
        }
        
        try Task.checkCancellation()
        
        return try await task()
    }
    
    // MARK: Private Instance Interface
    
    private func setUpTask() async {
        if maxConcurrentTaskCount <= numberOfRunningTasks {
            await withUnsafeContinuation {
                pendingContinuations.append($0)
            }
        }
        
        numberOfRunningTasks += 1
    }
    
    private func tearDownTask() {
        numberOfRunningTasks -= 1
        
        if !pendingContinuations.isEmpty {
            pendingContinuations.removeFirst().resume()
        }
    }
}
