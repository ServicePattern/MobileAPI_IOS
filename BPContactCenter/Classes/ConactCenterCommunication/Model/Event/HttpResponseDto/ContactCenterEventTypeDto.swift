//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// Contains all possible even types either serve or client ones
/// - Tag: ContactCenterEventTypeDto
enum ContactCenterEventTypeDto: String, Codable, CaseIterable {
    case chatSessionStatus = "chat_session_status"
    case chatSessionMessage = "chat_session_message"
    case chatSessionMessageDelivered = "chat_session_message_delivered"
    case chatSessionMessageRead = "chat_session_message_read"
    case chatSessionPartyJoined = "chat_session_party_joined"
    case chatSessionPartyLeft = "chat_session_party_left"
    case chatSessionTimeoutWarning = "chat_session_timeout_warning"
    case chatSessionInactivityTimeout = "chat_session_inactivity_timeout"
    case chatSessionEnded = "chat_session_ended"
    case chatSessionDisconnect = "chat_session_disconnect"
    case chatSessionEnd = "chat_session_end"

    /// Makes a correspondence between an even type and a particular event Dto JSON codable object
    var codableType: Codable.Type {
        switch self {
        case .chatSessionStatus:
            return ChatSessionStatusDto.self
        case .chatSessionMessage:
            return ChatSessionMessageDto.self
        case .chatSessionMessageDelivered:
            return ChatSessionMessageDeliveredDto.self
        case .chatSessionMessageRead:
            return ChatSessionMessageReadDto.self
        case .chatSessionPartyJoined:
            return ChatSessionPartyJoinedDto.self
        case .chatSessionPartyLeft:
            return ChatSessionPartyLeftDto.self
        case .chatSessionTimeoutWarning:
            return ChatSessionTimeoutWarningDto.self
        case .chatSessionInactivityTimeout:
            return ChatSessionInactivityTimeoutDto.self
        case .chatSessionEnded:
            return ChatSessionEndedDto.self
        case .chatSessionDisconnect:
            return ChatSessionDisconnectDto.self
        case .chatSessionEnd:
            return ChatSessionEndDto.self
        }
    }

    func decodeDto(from decoder: Decoder) throws -> ContactCenterEventModelConvertible {
        guard let dtoConvertible = try codableType.init(from: decoder) as? ContactCenterEventModelConvertible else {

            throw ContactCenterError.failedToCast("to: \(ContactCenterEventModelConvertible.self)")
        }

        return dtoConvertible
    }
}
