//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Describes API errors.
/// - Tag: ContactCenterError
public enum ContactCenterError: Error {
    /// The `baseURL` parameter provided during `ContactCenterCommunicator` instance creation does not represent valid HTTP URL.
    case failedToBuildBaseURL
    /// The REST request payload received from the server is not in JSON format.
    case failedToCodeJSON(nestedErrors: [Error])
    /// Unable to create valid HTTP request.
    case failedToCreateURLRequest
    /// Unknown error code received from the server.
    case badStatusCode(statusCode: Int, ContactCenterErrorResponse?)
    /// Unexpected response received from the server.
    case unexpectedResponse(URLResponse?)
    /// An application attempted to send the request with empty payload.
    case dataEmpty
    /// An unknown event received from the server.
    case failedToCast(String)
    /// Chat session has already been ended.
    case chatSessionNotFound
    /// Application attempted to call `getCaseHistory` or `closeCase` API requests before server specified a CRM case for the session (before `chatSessionCaseSet` event is received).
    case chatSessionCaseNotSpecified
}
