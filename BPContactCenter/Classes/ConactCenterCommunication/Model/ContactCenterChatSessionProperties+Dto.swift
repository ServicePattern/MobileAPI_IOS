//
// Copyright © 2019 Robert Bosch GmbH. All rights reserved. 
    

import Foundation

extension ContactCenterChatSessionState {
    func toDto() -> ChatSessionStateDto {
        switch self {
        case .queued:
            return .queued
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .ivr:
            return .ivr
        case .failed:
            return .failed
        case .completed:
            return .completed
        }
    }
}
