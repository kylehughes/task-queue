//
//  TaskQueueTests.swift
//  TaskQueue
//
//  Created by Kyle Hughes on 10/7/22.
//

import XCTest

@testable import TaskQueue

final class TaskQueueTests: XCTestCase {
    // MARK: XCTestCase Implementation
}

// MARK: - Initialization Tests

extension TaskQueueTests {
    // MARK: Tests
    
    func test_initialization_maxConcurrentTaskCount() async {
        let expectedMaxConcurrentTaskCount = 6
        
        let queue = TaskQueue(maxConcurrentTaskCount: 6)
        let maxConcurrentTaskCount = await queue.maxConcurrentTaskCount
        
        XCTAssertEqual(maxConcurrentTaskCount, expectedMaxConcurrentTaskCount)
    }
    
    func test_initialization_urlSession() async {
        let urlSession: URLSession = .shared
        
        let queue = TaskQueue(for: urlSession)
        let maxConcurrentTaskCount = await queue.maxConcurrentTaskCount
        
        XCTAssertEqual(maxConcurrentTaskCount, urlSession.configuration.httpMaximumConnectionsPerHost)
    }
}

// MARK: - Recursion Tests

extension TaskQueueTests {
    // MARK: Tests
    
    func test_recursion_concurrent() async throws {
        let queue = TaskQueue(maxConcurrentTaskCount: 2)
        
        await queue.add {
            await queue.add {
                ()
            }
        }
    }
    
    func test_recursion_serial() async {
        let expectation = expectation(description: "Recursive calls should deadlock on serial queues.")
        expectation.isInverted = true
        
        let queue = TaskQueue(maxConcurrentTaskCount: 1)

        Task {
            await queue.add {
                await queue.add {
                    ()
                }
            }
            
            expectation.fulfill()
        }
        
        await waitForExpectations(timeout: 0.5) {
            XCTAssertNil($0)
        }
    }
}
