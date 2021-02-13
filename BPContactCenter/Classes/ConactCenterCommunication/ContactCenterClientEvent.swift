//
// Copyright © 2021 BrightPattern. All rights reserved. 

import Foundation

/// Client Events that are received from the backend
/// - Tag: ContactCenterClientEvent
public enum ContactCenterClientEvent {
    /// Contains a new chat message
    case chatSessionMessage(messageID: String, chatId: String, messageNumber: Int, message: String)
    case chatSessionTyping
    case chatSessionNotTyping
}
