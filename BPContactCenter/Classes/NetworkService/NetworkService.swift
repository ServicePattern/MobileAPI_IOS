//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

class NetworkService {
    /// Used to set a`URLRequest`'s HTTP Method
    enum HttpMethod: String {
        case get = "GET"
        case patch = "PATCH"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
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

    /// Create a request given requestMethod  (get, post, create, etc...),  a URL,  and header fields
    func createRequest(method: HttpMethod, url: URL, headerFields: HttpHeaderFields? = nil, body: Encodable? = nil) -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.set(headerFields: headerFields?.stringDictionary)
        request.httpBody = body?.encode(using: encoder)

        log.debug("\(request.cURL)")

        return request
    }

    /// Create a request given requestMethod  (get, post, create, etc...),  a base URL, endpoint and header fields
    /// To create  a request with special header files that represent authorization, content type and user agent use [HttpHeaderFields](x-source-tag://HttpHeaderFields)
    /// That header fields are usually sent inside the requests to the backend
    /// Exception might be done for requests that load data from AWS for ex.
    ///  Parameters baseURL and endpoint are used to build a complete URL
    /// - Tag: createRequest
    func createRequest(method: HttpMethod, baseURL: URL, endpoint: URLProvider.Endpoint, headerFields: HttpHeaderFields, parameters: Encodable? = nil, body: Encodable? = nil) throws -> URLRequest? {

        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let basePath = urlComponents?.path ?? ""
        urlComponents?.path = basePath.appendingPathComponents(endpoint.endpointPathString)
        urlComponents?.queryItems = parameters?.queryItems

        guard let url = urlComponents?.url else {
            fatalError("Failed to build URL: method \(method) baseURL \(baseURL) endpoint \(endpoint)")
        }

        return createRequest(method: method,
                             url: url,
                             headerFields: headerFields,
                             body: body)
    }

    func decode<T: Decodable>(to type: T.Type, data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            log.error("Failed to decode: \(error)")
            throw ContactCenterError.failedToCodeJCON(nestedErrors: [error])
        }
    }

    func encode<T: Encodable>(from instance: T, request: URLRequest) throws -> URLRequest {
        var request = request
        do {
            request.httpBody = try encoder.encode(instance)
            return request
        } catch {
            log.error("Failed to encode: \(error)")
            throw ContactCenterError.failedToCodeJCON(nestedErrors: [error])
        }

    }
}

extension NetworkService: NetworkSessionServiceable {
    /// Delegate job to the URLSession
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkDataResponse) -> Void) {
        networkSessionService.dataTask(using: request, with: completion)
    }

    func dataTask<T: Decodable>(using request: URLRequest, with completion: @escaping (Result<T, Error>) -> Void) {
        dataTask(using: request) { [unowned self] response in
            switch response {
            case .success((let data, _)):
                guard let data = data else {
                    log.error("Data is empty for request: \(request)")
                    completion(.failure(ContactCenterError.dataEmpty))
                    return
                }
                var decodedString = String(decoding: data, as: UTF8.self)
                decodedString = decodedString.isEmpty ? "\(data)": decodedString
                log.debug("Received data: \(decodedString)")
                do {
                    let decodedObject: T = try self.decode(to: T.self, data: data)
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
}
