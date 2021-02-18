//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

extension ContactCenterEvent {
    func toDto() -> Encodable {
        switch self {
        case .chatSessionMessage(messageID: let messageID, partyID: let partyID, message: let message, timestamp: let timestamp):
            return ChatSessionMessageDto(event: <#T##ContactCenterEventTypeDto#>, messageID: <#T##String#>, partyID: <#T##String?#>, message: <#T##String#>, timestamp: <#T##Date?#>)
        case .chatSessionStatus(state: let state, ewt: let ewt):
            <#code#>
        case .chatSessionEnded:
            <#code#>
        case .chatSessionPartyJoined(partyID: let partyID, firstName: let firstName, lastName: let lastName, displayName: let displayName, type: let type, timestamp: let timestamp):
            <#code#>
        }
    }
}
