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
        if error_code == "5005" {
            return .chatSessionNotFound
        }
        else if error_code == "406" {
            return .chatSessionCaseNotSpecified
        }
        return nil
    }
}
