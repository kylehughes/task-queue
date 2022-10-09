//
//  URLSession+TaskQueue.swift
//  TaskQueue
//
//  Created by Kyle Hughes on 10/8/22.
//

import Foundation

extension URLSession {
    // MARK: Associated Task Queues
    
    /// The queue used by the incoming-oriented `*Concurrently` functions (e.g. `data`, `download`) to constrain the
    /// number of concurrent tasks for this object.
    public var incomingTaskingQueue: TaskQueue {
        objc_getOrMakeAssociatedObject(on: self, for: &AssociatedKey.incomingTaskQueue, factory: TaskQueue.init)
    }
    
    /// The queue used by the outgoing-oriented `*Concurrently` functions (i.e. `upload`) to constrain the number of
    /// concurrent tasks for this object.
    public var outgoingTaskingQueue: TaskQueue {
        objc_getOrMakeAssociatedObject(on: self, for: &AssociatedKey.outgoingTaskQueue, factory: TaskQueue.init)
    }
    
    // MARK: Performing Concurrent Asynchronous Transfers
    
    /// Returns a byte stream that conforms to AsyncSequence protocol.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data stream and response.
    @available(iOS 15.0, *)
    public func bytesConcurrently(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await bytes(for: request, delegate: delegate)
        }
    }
    
    /// Returns a byte stream that conforms to AsyncSequence protocol.
    ///
    /// - Parameter url: The URL for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data stream and response.
    @available(iOS 15.0, *)
    public func bytesConcurrently(
        from url: URL,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await bytes(from: url, delegate: delegate)
        }
    }
    
    /// Convenience method to load data using an URLRequest, creates and resumes an URLSessionDataTask internally.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    @available(iOS 15.0, *)
    public func dataConcurrently(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await data(for: request, delegate: delegate)
        }
    }

    /// Convenience method to load data using an URL, creates and resumes an URLSessionDataTask internally.
    ///
    /// - Parameter url: The URL for which to load data.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    @available(iOS 15.0, *)
    public func dataConcurrently(
        from url: URL,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await data(from: url, delegate: delegate)
        }
    }
    
    /// Convenience method to download using an URLRequest, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to download.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
    @available(iOS 15.0, *)
    public func downloadConcurrently(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (URL, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await download(for: request, delegate: delegate)
        }
    }
    
    /// Convenience method to download using an URL, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter url: The URL for which to download.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
    @available(iOS 15.0, *)
    public func downloadConcurrently(
        from url: URL,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (URL, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await download(from: url, delegate: delegate)
        }
    }
    
    /// Convenience method to upload data using an URLRequest, creates and resumes an URLSessionUploadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to upload data.
    /// - Parameter bodyData: Data to upload.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    @available(iOS 15.0, *)
    public func uploadConcurrently(
        for request: URLRequest,
        from bodyData: Data,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await upload(for: request, from: bodyData, delegate: delegate)
        }
    }
    
    /// Convenience method to upload data using an URLRequest, creates and resumes an URLSessionUploadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to upload data.
    /// - Parameter fileURL: File to upload.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Data and response.
    @available(iOS 15.0, *)
    public func uploadConcurrently(
        for request: URLRequest,
        fromFile fileURL: URL,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        try await incomingTaskingQueue.add { [self] in
            try await upload(for: request, fromFile: fileURL, delegate: delegate)
        }
    }
}

// MARK: - AssociatedKey Definition

private enum AssociatedKey {
    fileprivate static var incomingTaskQueue: Void? = nil
    fileprivate static var outgoingTaskQueue: Void? = nil
}

// MARK: - Associated Object Convenience

private func objc_getOrMakeAssociatedObject<Target, AssociatedObject>(
    on target: Target,
    for key: UnsafeRawPointer,
    policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN,
    factory: (Target) -> AssociatedObject
) -> AssociatedObject {
    guard let existingObject = objc_getAssociatedObject(target, key) as? AssociatedObject else {
        let newObject = factory(target)
        objc_setAssociatedObject(target, key, newObject, policy)
        
        return newObject
    }
    
    return existingObject
}
