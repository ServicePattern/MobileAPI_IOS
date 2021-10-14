//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

extension Data {
    func httpBodyEncoded(boundary: String, fileName: String, contentType: HttpHeaderContentType) -> Data {
        var data = Data()
        // Add data from a specific file to the raw http request body
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("\(HttpHeaderType.contentDisposition.rawValue): form-data; name=\"file-upload-input\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("\(HttpHeaderType.contentType.rawValue): \(contentType.rawValue)\r\n\r\n".data(using: .utf8)!)
        data.append(self)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return data
    }
}
