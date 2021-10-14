//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Text representation of mime types
enum HttpHeaderContentType: String {
    case json = "application/json"
    case multipart = "multipart/form-data"
    case image = "image/jpeg"
}

/// Used when the endpoint requires a header-type (i.e. "content-type") be specified in the header
enum HttpHeaderType: String {
    case contentType = "Content-Type"
    case contentDisposition = "Content-Disposition"
    case authorization = "Authorization"
    case userAgent = "UserAgent"
    case cacheControl = "Cache-Control"
}

/// The value of the header-type (i.e. "application/json")
enum HttpHeaderValue: CustomStringConvertible {
    case json
    case authorization(appID: String, clientID: String)
    case mobileClient
    case noCache
    case multipart(boundary: String)

    var description: String {
        switch self {
        case .json:
            return "\(HttpHeaderContentType.json.rawValue); charset=utf-8"
        case .authorization(let appID, let clientID):
            return "MOBILE-API-140-327-PLAIN appId=\(appID), clientId=\(clientID)"
        case .mobileClient:
            return "MobileClient"
        case .noCache:
            return "no-cache"
        case .multipart(let boundary):
            return "\(HttpHeaderContentType.multipart.rawValue); boundary=\(boundary)"
        }
    }
}

/// - Tag: HttpHeaderFields
struct HttpHeaderFields {
    let fields: [HttpHeaderType: HttpHeaderValue]

    /// Create an instance with authorization, content type and user agent use that are usually sent with each request
    static func defaultFields(appID: String, clientID: String) -> HttpHeaderFields {
        HttpHeaderFields(fields:
                            [.authorization: .authorization(appID: appID, clientID: clientID),
                             .contentType: .json,
                             .userAgent: .mobileClient,
                             .cacheControl: .noCache]
        )
    }

    /// Converts to a string dictionary to set it to URL request header fields property
    var stringDictionary: [String: String] {
        Dictionary(uniqueKeysWithValues: fields.map { key, value in
            (key.rawValue, "\(value)")
        })
    }

    /// Might be used to merge two header fields dictionaries together
    /// ```
    /// let specialHttpHeaderFields:[HttpHeaderType: HttpHeaderValue] = [
    ///     .specialType, .specialValue
    ///     ]
    /// let headerFieldsToBuildURLRequest = HttpHeaderFields.defaultFields(appID: "1",
    ///                                                                  clientID: "2")
    ///                                                     .merging(specialHttpHeaderFields)
    /// ```
    func merging(_ headerFieldsToMerge: HttpHeaderFields, _ replace: Bool = false) -> HttpHeaderFields {
        
        if (replace) {
            let mergedFields = fields.merging(headerFieldsToMerge.fields)  { (_, new) in new }
            return HttpHeaderFields(fields: mergedFields)
        } else {
            let mergedFields = fields.merging(headerFieldsToMerge.fields)  { (current, _) in current }
            return HttpHeaderFields(fields: mergedFields)
        }
    }
}
