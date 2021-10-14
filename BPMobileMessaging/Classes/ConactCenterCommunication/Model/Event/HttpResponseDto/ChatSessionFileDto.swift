//
//  ChatSessionFileDto.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 5/28/21.
//

import Foundation

/// Represents a file event
/// - Tag: ChatSessionFileDto
struct ChatSessionFileDto: Codable {
    let event: ContactCenterEventTypeDto
    let messageID: String?
    let partyID: String?
    let fileID: String
    let fileName: String
    let fileType: String
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case event
        case messageID = "msg_id"
        case partyID = "party_id"
        case fileID = "file_id"
        case fileName = "file_name"
        case fileType = "file_type"
        case timestamp
    }

    init(messageID: String?, partyID: String?, fileID: String, fileName: String, fileType: String, timestamp: Date?) {
        self.event = .chatSessionFile
        self.messageID = messageID
        self.partyID = partyID
        self.fileID = fileID
        self.fileName = fileName
        self.fileType = fileType
        self.timestamp = timestamp
    }
}

extension ChatSessionFileDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionFile(messageID: messageID, partyID: partyID, fileID: fileID, fileName: fileName, fileType: fileType, timestamp: timestamp)
    }
}
