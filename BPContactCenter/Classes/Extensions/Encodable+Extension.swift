//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

extension URLRequest {
    public var cURL: String {
        // Add Expect: to avoid getting Expect: 100-continue responses
        var result = "curl -k -H \"Expect:\" \\\n"

        result += "-X \(httpMethod) \\\n"

        if let headers = allHTTPHeaderFields {
            for (header, value) in headers {
                result += "-H \"\(header): \(value)\" \\\n"
            }
        }
        if let data = self.httpBody, !data.isEmpty, let string = String(data: data, encoding: .utf8), !string.isEmpty {
            result += "-d '\(string)' \\\n"
        }

        result += url?.absoluteString ?? ""

        return result
    }
}

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }

    var queryItems: [URLQueryItem]? {
        dictionary?.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
    }
}
