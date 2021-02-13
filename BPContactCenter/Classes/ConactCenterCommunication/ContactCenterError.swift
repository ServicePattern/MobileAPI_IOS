//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Describes general errors
/// - Tag: ContactCenterError
public enum ContactCenterError: Error {
    case failedToBuildBaseURL
    case failedToCodeJCON(Error)
    case failedToCreateURLRequest
    case badStatusCode(statusCode: Int, ContactCenterErrorResponse?)
    case unexpectedResponse(URLResponse?)
    case dataEmpty
}
