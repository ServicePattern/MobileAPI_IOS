//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

typealias NetworkDataResponse = Result<(Data?, URLResponse?), Error>

protocol NetworkSessionServiceable {
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkDataResponse) -> Void)
}

extension URLSession: NetworkSessionServiceable {
    func dataTask(using request: URLRequest, with completion: @escaping (NetworkDataResponse) -> Void) {
        self.dataTask(with: request) { (data, response, error) in

            let networkResponse: NetworkDataResponse

            defer {
                completion(networkResponse)
            }

            if let error = error {
                log.error("Network request failed: \(String(describing: request.url?.absoluteString)): \n\(error)")
                networkResponse = .failure(error)
            } else if let response = response as? HTTPURLResponse {
                let statusCode = response.statusCode
                guard statusCode == 200 else {
                    log.error("Bad status code: \(statusCode)")
                    guard let data = data else {
                        networkResponse = .failure(ContactCenterError.badStatusCode(statusCode: statusCode, nil))
                        return
                    }
                    do {
                        let errorResponse = try JSONDecoder().decode(ContactCenterErrorResponse.self, from: data)
                        networkResponse = .failure(ContactCenterError.badStatusCode(statusCode: statusCode, errorResponse))
                    } catch {
                        log.error("Failed to decode JSON: \(error)")
                        networkResponse = .failure(ContactCenterError.badStatusCode(statusCode: statusCode, nil))
                    }
                    return
                }
                networkResponse = .success((data, response))
            } else {
                networkResponse = .failure(ContactCenterError.unexpectedResponse(response))
            }
        }
        .resume()
    }
}
