//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

typealias NetworkDataResponse = Result<(Data?, URLResponse?), Error>

protocol NetworkSessionServiceable {
    @discardableResult
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkDataResponse) -> Void) -> URLSessionDataTask
}

extension URLSession: NetworkSessionServiceable {
    @discardableResult
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkDataResponse) -> Void) -> URLSessionDataTask {
        let task = dataTask(with: request) { (data, response, error) in

            let networkResponse: NetworkDataResponse

            if let error = error {
                log.error("Network request failed: \(String(describing: request.url?.absoluteString)): \n\(error)")
                networkResponse = .failure(error)
            } else if let response = response as? HTTPURLResponse {
                let statusCode = response.statusCode
                if statusCode == 200 {
                    networkResponse = .success((data, response))
                } else {
                    log.error("Bad status code: \(statusCode)")
                    if let data = data {
                        do {
                            let errorResponse = try JSONDecoder().decode(ContactCenterErrorResponse.self, from: data)
                            networkResponse = .failure(ContactCenterError.badStatusCode(statusCode: statusCode, errorResponse))
                        } catch {
                            log.error("Failed to decode JSON: \(error)")
                            networkResponse = .failure(ContactCenterError.badStatusCode(statusCode: statusCode, nil))
                        }
                    } else {
                        networkResponse = .failure(ContactCenterError.badStatusCode(statusCode: statusCode, nil))
                    }
                }
            } else {
                networkResponse = .failure(ContactCenterError.unexpectedResponse(response))
            }

            completion(networkResponse)
        }

        task.resume()

        return task
    }
}
