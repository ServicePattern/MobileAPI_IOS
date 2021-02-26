//
//  ChatSessionLocationDto.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/25/21.
//

import Foundation

/// - Tag: ChatSessionLocationDto
struct ChatSessionLocationDto: Codable {
    let event: ContactCenterEventTypeDto
    let partyID: String?
    let url: String?
    let latitudeString: String
    let longitudeString: String
    let timestamp: Date?

    var latitude: Float { return Float(latitudeString) ?? 0 }
    var longitude: Float { return Float(longitudeString) ?? 0 }

    enum CodingKeys: String, CodingKey {
        case event
        case partyID = "party_id"
        case url
        case latitudeString = "latitude"
        case longitudeString = "longitude"
        case timestamp
    }

    init(partyID: String?, url: String?, latitude: Float, longitude: Float, timestamp: Date?) {
        self.event = .chatSessionLocation
        self.partyID = partyID
        self.url = url
        self.latitudeString = String(latitude)
        self.longitudeString = String(longitude)
        self.timestamp = timestamp
    }
}

extension ChatSessionLocationDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionLocation(partyID: partyID, url: url, latitude: latitude, longitude: longitude,  timestamp: timestamp)
    }
}
