//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// Represents a message client event
/// - Tag: ChatSessionClientMessageDto
struct ChatSessionClientMessageDto: Codable {
    let event: ContactCenterEventTypeDto
    let messageID: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case event
        case messageID = "msg_id"
        case message = "msg"
    }
}

extension ChatSessionClientMessageDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEventProtocol {
        ContactCenterClientEvent.chatSessionMessage(messageID: messageID, message: message)
    }
}

/// Represents a message server event
/// - Tag: ChatSessionServerMessageDto
struct ChatSessionServerMessageDto: Codable {
    let event: ContactCenterEventTypeDto
    let messageID: String
    let partyID: String
    let message: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case event
        case messageID = "msg_id"
        case partyID = "party_id"
        case message = "msg"
        case timestamp
    }
}

extension ChatSessionServerMessageDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEventProtocol {
        ContactCenterServerEvent.chatSessionMessage(messageID: messageID, partyID: partyID, message: message, timestamp: timestamp)
    }
}

/// Encode/decode both client and server message event type
/// Decode events that have different representation for client and server type
/// If decoding fails for one type it assumes that data parameter contains a different type(client or server) and tries to decode a second time using its type
/// - Tag: ChatSessionMessageDto
struct ChatSessionMessageDto: Codable {
    let clientMessageEvent: ChatSessionClientMessageDto?
    let serverMessageEvent: ChatSessionServerMessageDto?

    init(from decoder: Decoder) throws {
        do {
            // Try to decode a server message first because it contains more properties
            // If we decode a client message first it will succeed in all the cases
            // It happens because a client message event is a subset of a server message event
            let container = try decoder.singleValueContainer()
            serverMessageEvent = try container.decode(ChatSessionServerMessageDto.self)
            clientMessageEvent = nil
        } catch let serverEventDecodingError {
            // Let's skip key not found error since this method handles both client and server events
            // The data that comes from the backend may contain a client event
            // So try to decode it as a next step
            guard case DecodingError.keyNotFound = serverEventDecodingError else {
                throw serverEventDecodingError
            }
            // Try to decode a server event
            do {
                let container = try decoder.singleValueContainer()
                clientMessageEvent = try container.decode(ChatSessionClientMessageDto.self)
                serverMessageEvent = nil
            } catch {
                // If inner decoding fails it makes sense to return the outer one to a consumer
                throw ContactCenterError.failedToCodeJCON(nestedErrors: [serverEventDecodingError, error])
            }
        }
    }

    func encode(to encoder: Encoder) throws {
    }
}

extension ChatSessionMessageDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEventProtocol {
        if let serverMessageEvent = serverMessageEvent {
            return serverMessageEvent.toModel()
        } else if let clientMessageEvent = clientMessageEvent {
            return clientMessageEvent.toModel()
        } else {
            fatalError("Neither client nor server message event set")
        }
    }
}
