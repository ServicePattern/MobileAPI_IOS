//
//  ChatSessionInactivityTimeout.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

/// Represents an inactivity timeout event
/// - Tag: ChatSessionInactivityTimeoutDto
struct ChatSessionInactivityTimeoutDto: Codable {
    let event: ContactCenterEventTypeDto
    let message: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case event
        case message = "msg"
        case timestamp
    }
}

extension ChatSessionInactivityTimeoutDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionInactivityTimeout(message: message, timestamp: timestamp)
    }
}
