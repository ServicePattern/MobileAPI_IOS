//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

typealias NetworkVoidResponse = Result<Void, Error>

/// Used to set a`URLRequest`'s HTTP Method
enum HttpMethod: String {
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

protocol NetworkServiceable {
    /// Create a request given requestMethod  (get, post, create, etc...),  a URL,  and header fields
    func createRequest(method: HttpMethod, url: URL, headerFields: HttpHeaderFields?, body: Encodable?) -> URLRequest
    /// Create a request given requestMethod  (get, post, create, etc...),  a base URL, endpoint and header fields
    /// To create  a request with special header files that represent authorization, content type and user agent use [HttpHeaderFields](x-source-tag://HttpHeaderFields)
    /// That header fields are usually sent inside the requests to the backend
    /// Exception might be done for requests that load data from AWS for ex.
    ///  Parameters baseURL and endpoint are used to build a complete URL
    /// - Tag: createRequest
    func createRequest(method: HttpMethod, baseURL: URL, endpoint: URLProvider.Endpoint, headerFields: HttpHeaderFields, parameters: Encodable?, body: Encodable?) throws -> URLRequest?
    func decode<T: Decodable>(to type: T.Type, data: Data) throws -> T
    func encode<T: Encodable>(from instance: T, request: URLRequest) throws -> URLRequest
    @discardableResult
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkDataResponse) -> Void) -> URLSessionDataTask
    @discardableResult
    func dataTask<T: Decodable>(using request: URLRequest, with completion: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask
    @discardableResult
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkVoidResponse) -> Void) -> URLSessionDataTask
}

extension NetworkServiceable {
    // MARK:- Allows to specify fewer parameters
    func createRequest(method: HttpMethod, baseURL: URL, endpoint: URLProvider.Endpoint, headerFields: HttpHeaderFields) throws -> URLRequest? {
        try createRequest(method: method, baseURL: baseURL, endpoint: endpoint, headerFields: headerFields, parameters: nil, body: nil)
    }

    func createRequest(method: HttpMethod, baseURL: URL, endpoint: URLProvider.Endpoint, headerFields: HttpHeaderFields, parameters: Encodable?) throws -> URLRequest? {
        try createRequest(method: method, baseURL: baseURL, endpoint: endpoint, headerFields: headerFields, parameters: parameters, body: nil)
    }

    func createRequest(method: HttpMethod, url: URL) -> URLRequest {
        return createRequest(method: method, url: url, headerFields: nil, body: nil)
    }
}
