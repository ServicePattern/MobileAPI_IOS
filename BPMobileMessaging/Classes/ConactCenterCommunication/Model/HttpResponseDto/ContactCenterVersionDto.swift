//
//  ContactCenterVersionDto.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 4/12/21.
//

import Foundation

/// - Tag: ContactCenterVersionDto
struct ContactCenterVersionDto: Decodable {
    let serverVersion: String
    
    enum CodingKeys: String, CodingKey {
        case serverVersion = "server_version"
    }
}

extension ContactCenterVersionDto {
    func toModel() -> ContactCenterVersion {
        ContactCenterVersion(serverVersion: serverVersion)
    }
}
