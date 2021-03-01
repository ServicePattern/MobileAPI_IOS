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
        case "5005":
            return .chatSessionNotFound
        case "406":
            return .chatSessionCaseNotSpecified
        default:
            return nil
        }
    }
}
