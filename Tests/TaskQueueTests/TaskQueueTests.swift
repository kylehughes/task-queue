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

// MARK: - General Tests

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
    
//    func test_recursion_serial() async throws {
//        let queue = TaskQueue(maxConcurrentTaskCount: 1)
//
//        await queue.add {
//            await queue.add {
//                ()
//            }
//        }
//    }
}
