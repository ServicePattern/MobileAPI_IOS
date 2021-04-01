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
    /// Missing or invalid tenantUrl.
    case chatSessionBadTenantUrl
    /// Authorization header is missing
    case chatSessionNoAuthHeader
    /// Authorization parameter format is incorrect
    case chatSessionAuthHeaderWrongFormat
    /// Authorization scheme is incorrect
    case chatSessionAuthHeaderBadScheme
    /// Authorization parameter is missing: appId
    case chatSessionAuthHeaderMissingAppId
    /// Authorization parameter is missing: clientId
    case chatSessionAuthHeaderMissingClientId
    /// Missing or invalid application unique id
    case chatSessionAuthHeaderBadAppId
    /// Chat server takes too long to respond
    case chatSessionServerTimeout
    /// No server is available to accept chat session
    case chatSessionServerNotAvailable
    /// Error decoding JSON request body
    case chatSessionInvalidJson
    /// Chat server disconnected
    case chatSessionServerDisconnected
    /// Launch Point (application) is not found
    case chatSessionEntryNotFound
    /// Internal server error
    case chatSessionInternalServerError
    /// Upload size limit exceeded
    case chatSessionUploadSizeLimitExceeded
    /// File not found
    case chatSessionFileNotFound
    /// Too many concurrent poll requests for the same session
    case chatSessionTooManyPollRequests
    /// No events
    case chatSessionNoEvents
    /// File I/O error
    case chatSessionFileError
    /// Unspecified server error
    case chatSessionUnspecifiedServerError
    /// Chat session has already been ended.
    case chatSessionNotFound
    /// Application attempted to call `getCaseHistory` or `closeCase` API requests before server specified a CRM case for the session (before `chatSessionCaseSet` event is received).
    case chatSessionCaseNotSpecified
    /// CRM server error
    case chatSessionCrmServerError
    /// Too many concurrent parameters (i.e. both APNs and Firebase device tokens)
    case chatSessionTooManyParameters
}
