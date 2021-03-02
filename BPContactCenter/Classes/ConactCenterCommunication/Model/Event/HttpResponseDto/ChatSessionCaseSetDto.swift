//
//  ChatSessionCaseSetDto.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 3/1/21.
//

import Foundation

/// - Tag: ChatSessionCaseSetDto
struct ChatSessionCaseSetDto: Codable {
    let event: ContactCenterEventTypeDto
    let caseID: String?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case event
        case caseID = "case_id"
        case timestamp
    }

    init(caseID: String?, timestamp: Date) {
        self.event = .chatSessionCaseSet
        self.caseID = caseID
        self.timestamp = timestamp
    }
}

extension ChatSessionCaseSetDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionCaseSet(caseID: caseID, timestamp: timestamp)
    }
}
