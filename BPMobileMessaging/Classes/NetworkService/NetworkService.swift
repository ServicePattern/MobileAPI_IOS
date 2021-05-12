//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation
import CFNetwork

class NetworkService: NetworkServiceable {
    /// Might be used to switch between live and Mock Data
    private let networkSessionService: NetworkSessionServiceable
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    /// A parameter networkSessionService parameter might be used to mock networking functionality for unit testing
    init(networkSessionService: NetworkSessionServiceable = URLSession.shared, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.networkSessionService = networkSessionService
        self.encoder = encoder
        self.decoder = decoder
    }

    func createRequest(method: HttpMethod, url: URL, headerFields: HttpHeaderFields? = nil, body: Encodable? = nil) throws -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.set(headerFields: headerFields?.stringDictionary)
        request.httpBody = try body?.encode(using: encoder)

        return request
    }

    func createRequest(method: HttpMethod, baseURL: URL, endpoint: URLProvider.Endpoint, headerFields: HttpHeaderFields, parameters: Encodable? = nil, body: Encodable? = nil) throws -> URLRequest? {

        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let basePath = urlComponents?.path ?? ""
        urlComponents?.path = basePath.appendingPathComponents(endpoint.endpointPathString)
        urlComponents?.queryItems = parameters?.queryItems

        guard let url = urlComponents?.url else {
            fatalError("Failed to build URL: method \(method) baseURL \(baseURL) endpoint \(endpoint)")
        }

        return try createRequest(method: method,
                             url: url,
                             headerFields: headerFields,
                             body: body)
    }

    func decode<T: Decodable>(to type: T.Type, data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            log.error("Failed to decode: \(error)")
            throw ContactCenterError.failedToCodeJSON(nestedErrors: [error])
        }
    }
}

extension NetworkService: NetworkSessionServiceable {
    /// Delegate job to the URLSession
    @discardableResult
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkDataResponse) -> Void) -> URLSessionDataTask {
        return networkSessionService.dataTask(using: request, with: completion)
    }

    @discardableResult
    func dataTask<T: Decodable>(using request: URLRequest, with completion: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask {
        dataTask(using: request) { [unowned self] (response: NetworkDataResponse) in
            switch response {
            case .success((let data, _)):
                guard let data = data else {
                    log.error("Data is empty for request: \(request)")
                    completion(.failure(ContactCenterError.dataEmpty))
                    return
                }
                var decodedString = String(decoding: data, as: UTF8.self)
                decodedString = decodedString.isEmpty ? "\(data)": decodedString
                do {
                    let decodedObject: T = try decoder.decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                log.error("Request failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    @discardableResult
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkVoidResponse) -> Void) -> URLSessionDataTask {
        return dataTask(using: request) { (response: NetworkDataResponse) in
            switch response {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
