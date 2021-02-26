//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

extension ContactCenterChatSessionPartyType {
    func toDto() -> ChatSessionPartyTypeDto {
        switch self {
        case .scenario:
            return .scenario
        case .external:
            return .external
        case .internal:
            return .internal
        }
    }
}

extension ContactCenterEvent {
    func toDto() -> Encodable {
        switch self {
        case .chatSessionMessage(messageID: let messageID,
                                 partyID: let partyID,
                                 message: let message,
                                 timestamp: let timestamp):
            return ChatSessionMessageDto(messageID: messageID,
                                         partyID: partyID,
                                         message: message,
                                         timestamp: timestamp)
        case .chatSessionMessageDelivered(messageID: let messageID,
                                          partyID: let partyID,
                                          timestamp: let timestamp):
            return ChatSessionMessageDeliveredDto(messageID: messageID,
                                                  partyID: partyID,
                                                  timestamp: timestamp)
        case .chatSessionMessageRead(messageID: let messageID,
                                     partyID: let partyID,
                                     timestamp: let timestamp):
            return ChatSessionMessageReadDto(messageID: messageID,
                                             partyID: partyID,
                                             timestamp: timestamp)
        case .chatSessionStatus(state: let state,
                                estimatedWaitTime: let estimatedWaitTime):
            return ChatSessionStatusDto(state: state.toDto(),
                                        ewt: "\(estimatedWaitTime)")
        case .chatSessionPartyJoined(partyID: let partyID,
                                     firstName: let firstName,
                                     lastName: let lastName,
                                     displayName: let displayName,
                                     type: let type,
                                     timestamp: let timestamp):
            return ChatSessionPartyJoinedDto(partyID: partyID,
                                             firstName: firstName,
                                             lastName: lastName,
                                             displayName: displayName,
                                             type: type.toDto(),
                                             timestamp: timestamp)
        case .chatSessionPartyLeft(partyID: let partyID,
                                   timestamp: let timestamp):
            return ChatSessionPartyLeftDto(partyID: partyID,
                                           timestamp: timestamp)
        case .chatSessionTyping(partyID: let partyID,
                                     timestamp: let timestamp):
            return ChatSessionTypingDto(partyID: partyID,
                                         timestamp: timestamp)
        case .chatSessionNotTyping(partyID: let partyID,
                                        timestamp: let timestamp):
            return ChatSessionNotTypingDto(partyID: partyID,
                                         timestamp: timestamp)
        case .chatSessionLocation(partyID: let partyID,
                                  url: let url,
                                  latitude: let latitude,
                                  longitude: let longitude,
                                  timestamp: let timestamp):
            return ChatSessionLocationDto(partyID: partyID,
                                          url: url,
                                          latitude: latitude,
                                          longitude: longitude,
                                         timestamp: timestamp)
        case .chatSessionTimeoutWarning(message: let message,
                                        timestamp: let timestamp):
            return ChatSessionTimeoutWarningDto(message: message,
                                                timestamp: timestamp)
        case .chatSessionInactivityTimeout(message: let message,
                                           timestamp: let timestamp):
            return ChatSessionInactivityTimeoutDto(message: message,
                                                   timestamp: timestamp)
        case .chatSessionEnded:
            return ChatSessionEndedDto()
        case .chatSessionDisconnect:
            return ChatSessionDisconnectDto()
        case .chatSessionEnd:
            return ChatSessionEndDto()
        }
    }
}
