//
//  File.swift
//  InternxtSwiftCore
//
//  Created by Patricio Tovar on 30/6/25.
//

import Foundation
import XCTest

final class APIClientTests: XCTestCase {
    
    var client: APIClient!

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        client = APIClient(urlSession: session, rateLimitConfiguration: RateLimitConfiguration(
            maxRetries: 2, baseDelay: 0.1, maxDelay: 1.0, backoffMultiplier: 2.0
        ))
    }

    func test429WithRetryAfterHeader() async throws {
        var callCount = 0
        
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                let headers = ["Retry-After": "1"]
                let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: headers)!
                return (response, "{\"message\": \"Rate limited\"}".data(using: .utf8))
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, "{\"message\": \"OK\", \"statusCode\": 200}".data(using: .utf8))
            }
        }

        struct DummyResponse: Decodable {
            let message: String
            let statusCode: Int
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)

        let start = Date()
        let result: DummyResponse = try await client.fetch(type: DummyResponse.self, endpoint)
        let duration = Date().timeIntervalSince(start)

        XCTAssertEqual(result.message, "OK")
        XCTAssertTrue(duration >= 1.0, "Should wait 1s due to Retry-After")
    }

    func testServerErrorRetriesAndSucceeds() async throws {
        var callCount = 0

        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount < 3 {
                let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (response, "{\"message\": \"Internal Server Error\"}".data(using: .utf8))
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, "{\"message\": \"OK\", \"statusCode\": 200}".data(using: .utf8))
            }
        }

        struct DummyResponse: Decodable {
            let message: String
            let statusCode: Int
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)
        let result: DummyResponse = try await client.fetch(type: DummyResponse.self, endpoint)

        XCTAssertEqual(result.message, "OK")
        XCTAssertEqual(callCount, 3, "Should retry 2 times then succeed")
    }

    func testMaxRetriesExceeded() async {
        var callCount = 0

        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, "{\"message\": \"Server Error\"}".data(using: .utf8))
        }

        struct DummyResponse: Decodable {
            let message: String
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)

        do {
            _ = try await client.fetch(type: DummyResponse.self, endpoint)
            XCTFail("Expected to throw after max retries")
        } catch let err as APIClientError {
            XCTAssertEqual(err.statusCode, 500)
            XCTAssertEqual(callCount, 3, "Initial + 2 retries")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test429WithoutRetryAfter_UsesAdaptiveDelay() async throws {
        var callCount = 0

        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            let response = HTTPURLResponse(url: URL(string: "https://mock.test")!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, "{\"message\": \"Too many requests\"}".data(using: .utf8))
        }

        struct DummyResponse: Decodable {
            let message: String
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)

        do {
            _ = try await client.fetch(type: DummyResponse.self, endpoint)
            XCTFail("Expected to throw")
        } catch let error as APIClientError {
            XCTAssertEqual(error.statusCode, 429)
            XCTAssertEqual(callCount, 3, "Should retry maxRetries times")
        }
    }
    
    func testCancellationCancelsDataTask() async {
        let endpoint = Endpoint(path: "https://mock.test", method: .GET)

        MockURLProtocol.requestHandler = { _ in
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let response = HTTPURLResponse(url: URL(string: "https://mock.test")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "{\"message\": \"OK\", \"statusCode\": 200}".data(using: .utf8))
        }

        struct DummyResponse: Decodable {
            let message: String
            let statusCode: Int
        }

        let task = Task {
            try await client.fetch(type: DummyResponse.self, endpoint)
        }

        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Should throw CancellationError")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }
    

}

