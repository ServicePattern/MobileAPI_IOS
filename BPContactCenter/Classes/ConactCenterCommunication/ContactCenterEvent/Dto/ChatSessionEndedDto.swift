//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

struct ChatSessionEndedDto: Codable {
    let event: ContactCenterEventTypeDto
}

extension ChatSessionEndedDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEventProtocol {
        ContactCenterServerEvent.chatSessionEnded
    }
}
