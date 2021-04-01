//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Describes errors that might happen when communicating with Contact Center
/// - Tag: ContactCenterErrorResponse
public struct ContactCenterErrorResponse: Decodable {
    let error_code: String
    let error_message: String
}

extension ContactCenterErrorResponse {
    func toModel() -> ContactCenterError? {
        switch error_code {
        case "1000":
            return .chatSessionBadTenantUrl
        case "2000":
            return .chatSessionNoAuthHeader
        case "2001":
            return .chatSessionAuthHeaderWrongFormat
        case "2002":
            return .chatSessionAuthHeaderBadScheme
        case "2003":
            return .chatSessionAuthHeaderMissingAppId
        case "2004":
            return .chatSessionAuthHeaderMissingClientId
        case "3000":
            return .chatSessionAuthHeaderBadAppId
        case "5000":
            return .chatSessionServerTimeout
        case "5001":
            return .chatSessionServerNotAvailable
        case "5003":
            return .chatSessionInvalidJson
        case "5004":
            return .chatSessionServerDisconnected
        case "5005":
            return .chatSessionNotFound
        case "5006":
            return .chatSessionEntryNotFound
        case "5500":
            return .chatSessionInternalServerError
        case "5501":
            return .chatSessionUploadSizeLimitExceeded
        case "5502":
            return .chatSessionFileNotFound
        case "5509":
            return .chatSessionTooManyPollRequests
        case "5511":
            return .chatSessionNoEvents
        case "5558":
            return .chatSessionFileError
        case "5601":
            return .chatSessionCaseNotSpecified
        case "5602":
            return .chatSessionCrmServerError
        case "5603":
            return .chatSessionTooManyParameters
        case "5955":
            return .chatSessionUnspecifiedServerError
        default:
            return nil
        }
    }
}
