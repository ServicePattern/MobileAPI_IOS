//
//  ChatSessionSignalingDto.swift
//  BPMobileMessaging
//
//  Created by Artem Mkrtchyan on 3/17/23.
//

import Foundation

/// Represents a file event
/// - Tag: ChatSessionFileDto
struct ChatSessionSignalingDto: Codable {
    let event: ContactCenterEventTypeDto
    let data: SignalingData?
    let partyID: String?
    let destinationID: String?
    let msgID: String?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case event
        case data
        case partyID = "party_id"
        case destinationID = "destination_party_id"
        case msgID = "msg_id"
        case timestamp
    }
    
    init(partyID: String?, data: SignalingData?, msgID: String = "0", timestamp: Date? = nil) {
        self.event = .chatSessionSignaling
        self.data = data
        self.partyID = partyID
        self.destinationID = partyID
        self.msgID = msgID
        self.timestamp = timestamp ?? Date()
    }
    
}

// MARK: - DataClass
/// - Tag: SignalingData
public struct SignalingData: Codable {
    public let sdp, sdpMLineIndex, sdpMid, candidate: String?
    public let type: SignalingType
    
    enum CodingKeys: String, CodingKey {
        case sdp = "sdp"
        case candidate = "candidate"
        case sdpMLineIndex = "sdpMLineIndex"
        case sdpMid = "sdpMid"
        case type = "type"
    }
    
    public init(sdp: String? = nil, sdpMLineIndex: String? = nil, sdpMid: String? = nil, candidate: String? = nil, type: SignalingType) {
        self.sdp = sdp
        self.type = type
        self.candidate = candidate
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
    }
}


// MARK: - Signaling types
public enum SignalingType: String, Codable{
    case REQUEST_CALL, END_CALL, CALL_REJECTED, ANSWER_CALL, OFFER_CALL, ICE_CANDIDATE
}

extension ChatSessionSignalingDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionSignaling(partyID: partyID, data: data, timestamp: timestamp)
    }
}
