//
//  ApiClient.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation
import Combine

public struct APIClientError: Error {
    public var statusCode: Int
    public var responseBody: Data
    private var message: String

    public var localizedDescription: String {
        return self.message
    }

    public init(statusCode: Int, message: String, responseBody: Data = Data()) {
        self.statusCode = statusCode
        self.message = message
        self.responseBody = responseBody
    }
}

// MARK: - APIClient

@available(macOS 10.15, *)
struct APIClient {
    var urlSession: URLSession = .shared
    var authorizationHeaderValue: String? = nil
    var clientName: String? = nil
    var clientVersion: String? = nil
    var workspaceHeader: String? = nil
    var authorizationHeaderGatewayValue: String? = nil

    private let rateLimiter = RateLimiter(maxRequestsPerSecond: 4)

    func fetch<T: Decodable>(
        type: T.Type?,
        _ endpoint: Endpoint,
        debugResponse: Bool? = false
    ) async throws -> T {
        let request: URLRequest = try buildURLRequest(endpoint: endpoint)

        return try await withCheckedThrowingContinuation { continuation in
            let taskBlock = {
                let task = urlSession.dataTask(with: request) { data, response, error in
                    if let error = error {
                        if debugResponse == true {
                            print("❌ API CLIENT ERROR", error)
                        }
                        continuation.resume(with: .failure(APIClientError(statusCode: -1, message: error.localizedDescription)))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.resume(with: .failure(APIClientError(statusCode: -1, message: "Invalid response")))
                        return
                    }

                    do {
                        guard let data = data else {
                            throw APIClientError(statusCode: httpResponse.statusCode, message: "Empty response")
                        }

                        if debugResponse == true {
                            print("✅ \(endpoint.path) response: \(String(decoding: data, as: UTF8.self))")
                        }

                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(returning: decoded)
                    } catch {
                        continuation.resume(with: .failure(APIClientError(
                            statusCode: httpResponse.statusCode,
                            message: error.localizedDescription,
                            responseBody: data ?? Data()
                        )))
                    }
                }

                task.resume()
            }

            rateLimiter.enqueue(taskBlock)
        }
    }

    private func buildURLRequest(endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.path) else {
            throw APIClientError(statusCode: -1, message: "Unable to build URL from \(endpoint.path)")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue.uppercased()

        if let authorizationHeaderValue = self.authorizationHeaderValue {
            urlRequest.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        }

        if let workspaceHeaderValue = self.workspaceHeader {
            urlRequest.setValue(workspaceHeaderValue, forHTTPHeaderField: "x-internxt-workspace")
        }

        if let authorizationHeaderGatewayValue = self.authorizationHeaderGatewayValue {
            urlRequest.setValue(authorizationHeaderGatewayValue, forHTTPHeaderField: "x-internxt-desktop-header")
        }

        urlRequest.setValue(clientName, forHTTPHeaderField: "internxt-client")
        urlRequest.setValue(clientVersion, forHTTPHeaderField: "internxt-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = endpoint.body {
            urlRequest.httpBody = body
        }

        return urlRequest
    }
}

// MARK: - Rate Limiter

final class RateLimiter {
    private let maxRequestsPerSecond: Int
    private let queue = DispatchQueue(label: "com.internxt.api.ratelimiter", qos: .userInitiated)
    private var requestQueue: [() -> Void] = []
    private var timer: DispatchSourceTimer?

    init(maxRequestsPerSecond: Int) {
        self.maxRequestsPerSecond = maxRequestsPerSecond
        startTimer()
    }

    private func startTimer() {
        let interval = 1.0 / Double(maxRequestsPerSecond)

        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: interval)
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            if !self.requestQueue.isEmpty {
                let task = self.requestQueue.removeFirst()
                task()
            }
        }
        timer?.resume()
    }

    func enqueue(_ block: @escaping () -> Void) {
        queue.async {
            self.requestQueue.append(block)
        }
    }

    deinit {
        timer?.cancel()
    }
}
