//
//  ChatSessionCaseHistoryDto.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/26/21.
//

import Foundation

struct ChatSessionDto: Codable {
    let chatID: String
    let createdTime: Date
    let events: ContactCenterEventsContainerDto
    
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case createdTime = "created_time"
        case events
    }
    
    init(chatID: String, createdTime: Date, events: [ContactCenterEvent]) {
        self.chatID = chatID
        self.createdTime = createdTime
        self.events = ContactCenterEventsContainerDto(events: events)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.chatID = try container.decode(String.self, forKey: .chatID)
        self.createdTime = try container.decode(Date.self, forKey: .createdTime)
        self.events = try ContactCenterEventsContainerDto.init(from: decoder)
    }
}

extension ChatSessionDto {
    func toModel() -> ContactCenterChatSession {
        ContactCenterChatSession(chatID: chatID, createdTime: createdTime, events: events.events)
    }
}

/// - Tag: ChatSessionCaseHistoryDto
struct ChatSessionCaseHistoryDto: Codable {
    var sessions: [ContactCenterChatSession]
    
    enum CodingKeys: String, CodingKey {
        case sessions
    }

    init(sessions: [ContactCenterChatSession]) {
        self.sessions = sessions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var sessionsContainer = try container.nestedUnkeyedContainer(forKey: .sessions)
        self.sessions = [ContactCenterChatSession]()

        while !sessionsContainer.isAtEnd {
            do {
                let dtoConvertible = try ChatSessionDto.init(from: sessionsContainer.superDecoder())
                self.sessions.append(dtoConvertible.toModel())
            } catch {
                log.error("Failed to parse chat session: \(error)")
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var sessionsNestedContainer = container.nestedUnkeyedContainer(forKey: .sessions)
        sessions.forEach { session in
            do {
                try session.toDto().encode(to: sessionsNestedContainer.superEncoder())
            } catch {
                log.error("Failed to encode: \(error)")
            }
        }
    }
}

extension ChatSessionCaseHistoryDto {
    func toModel() -> ContactCenterCaseHistory {
        ContactCenterCaseHistory(sessions: sessions)
    }
}
