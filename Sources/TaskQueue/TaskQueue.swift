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
    private let maxConcurrentTaskCount: Int
    
    private var numberOfRunningTasks: Int
    private var pendingContinuations: [UnsafeContinuation<Void, Never>]
    
    // MARK: Public Initialization
    
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
