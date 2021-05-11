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
        
        self.logRequest(request: request)
        
        let task = dataTask(with: request) { (data, response, error) in

            let networkResponse: NetworkDataResponse

            if let error = error {
                log.error("Network request failed: \(String(describing: request.url?.absoluteString)): \n\(error)")
                networkResponse = .failure(error)
            } else if let response = response as? HTTPURLResponse {
                self.logResponse(data: data, response: response, error: error)
                let statusCode = response.statusCode
                if statusCode == 200 {
                    networkResponse = .success((data, response))
                } else {
                    log.error("Bad status code: \(statusCode)")
                    if let data = data {
                        do {
                            let errorResponse = try JSONDecoder().decode(ContactCenterErrorResponse.self, from: data)
                            if let contactCenterError = errorResponse.toModel() {
                                networkResponse = .failure(contactCenterError)
                            } else {
                                networkResponse = .failure(ContactCenterError.badStatusCode(statusCode: statusCode, errorResponse))

                            }
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
    
    func logRequest(request: URLRequest){

        let urlString = request.url?.absoluteString ?? ""
        let components = NSURLComponents(string: urlString)

        let method = request.httpMethod != nil ? "\(request.httpMethod!)": ""
        let path = "\(components?.path ?? "")"
        let query = "\(components?.query ?? "")"
        let host = "\(components?.host ?? "")"

        var requestLog = "\n---------- OUT ---------->\n"
        requestLog += "\(urlString)"
        requestLog += "\n\n"
        requestLog += "\(method) \(path)?\(query) HTTP/1.1\n"
        requestLog += "Host: \(host)\n"
        for (key,value) in request.allHTTPHeaderFields ?? [:] {
            requestLog += "\(key): \(value)\n"
        }
        if let body = request.httpBody{
            let bodyString = NSString(data: body, encoding: String.Encoding.utf8.rawValue) ?? "Can't render body; not utf8 encoded";
            requestLog += "\n\(bodyString)\n"
        }

        requestLog += "\n------------------------->\n";
        log.debug(requestLog)
    }
    
    func logResponse(data: Data?, response: HTTPURLResponse?, error: Error?){

        let urlString = response?.url?.absoluteString
        let components = NSURLComponents(string: urlString ?? "")

        let path = "\(components?.path ?? "")"
        let query = "\(components?.query ?? "")"

        var responseLog = "\n<---------- IN ----------\n"
        if let urlString = urlString {
            responseLog += "\(urlString)"
            responseLog += "\n\n"
        }

        if let statusCode =  response?.statusCode{
            responseLog += "HTTP \(statusCode) \(path)?\(query)\n"
        }
        if let host = components?.host{
            responseLog += "Host: \(host)\n"
        }
        for (key,value) in response?.allHeaderFields ?? [:] {
            responseLog += "\(key): \(value)\n"
        }
        if let body = data{
            let bodyString = NSString(data: body, encoding: String.Encoding.utf8.rawValue) ?? "Can't render body; not utf8 encoded";
            responseLog += "\n\(bodyString)\n"
        }
        if let error = error{
            responseLog += "\nError: \(error.localizedDescription)\n"
        }

        responseLog += "<------------------------\n";
        log.debug(responseLog)
    }
}
