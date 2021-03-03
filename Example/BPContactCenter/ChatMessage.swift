//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

enum TimeStampLabelAlignment : Int {
    ///  Timestamp labels will be horizontally aligned on the cell.
    case timeStampCenterAligned
    ///  Timestamp libels will be shown at the left or right side of the bubble.
    case timeStampSideAligned
}

enum MessageType : Int {
    case messageMine
    case messageSomeone
    case messageTypingMine
    case messageTypingSomeone
    case messageStatus
}

struct ChatAttachment {
    let fileId: String?
    let data: Data?
    let uti: String?
    let as_attachment: Bool
}

extension ChatAttachment: Hashable {
}

struct ChatProfileImage {
    let partyId: String?
    let data: Data?
}

extension ChatProfileImage: Hashable {
}

struct ChatMessage {
    let type: MessageType
    let text: String?
    let attachment: ChatAttachment?
    let senderName: String?
    let time: Date?
    let profileImage: ChatProfileImage?
    let chatID: String?
}

extension ChatMessage: Hashable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.type == rhs.type &&
            lhs.text == rhs.text &&
            lhs.time == rhs.time &&
            lhs.chatID == rhs.chatID
    }
}
