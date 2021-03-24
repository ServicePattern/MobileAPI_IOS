//
//  ContactCenterServiceAvailabilityDto.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 3/17/21.
//

import Foundation

/// - Tag: ContactCenterServiceAvailabilityDto
struct ContactCenterServiceAvailabilityDto: Decodable {
    let chat: ContactCenterServiceChatAvailability
    let ewt: String?
}

extension ContactCenterServiceAvailabilityDto {
    func toModel() -> ContactCenterServiceAvailability {
        ContactCenterServiceAvailability(chat: chat, estimatedWaitTime: Int(ewt ?? ""))
    }
}
