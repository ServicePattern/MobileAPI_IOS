//
//  WeRTCViewModel.swift
//  BPMobileMessaging_Example
//
//  Created by Artem Mkrtchyan on 4/25/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import WebRTC
import BPMobileMessaging

protocol WebRTCViewModelUpdatable: AnyObject {
    func goBack()
}


class WebRTCViewModel: NSObject {
    private let service: ServiceDependencyProtocol
    let currentChatID: String!
    let partyID: String!
    
    weak var delegate: WebRTCViewModelUpdatable?
    var webRTCClient: WebRTCClient!
    var useCustomCapturer: Bool = false
    
    
    init(service: ServiceDependencyProtocol, currentChatID: String, partyID: String) {
        self.service = service
        self.currentChatID = currentChatID
        self.partyID = partyID
        
        super.init()
        
        webRTCClient = WebRTCClient()
        webRTCClient.setup(videoTrack: true, audioTrack: true, dataChannel: false, customFrameCapturer: useCustomCapturer)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupAPI(){
        NotificationCenter.default.addObserver(self, selector: #selector(receivedEvents), name: NotificationName.contactCenterEventsReceived.name, object: nil)
        
        self.subscribeForNotifications() { subscribeResult in
            DispatchQueue.main.async {
                switch subscribeResult {
                case .success:
                    print("Subscribe for remote notifications confirmed")
                case .failure(let error):
                    print("Failed to subscribe for notifications: \(error)")
                }
            }
        }
    }
    
    func releaseAPI(){
        NotificationCenter.default.removeObserver(self)
    }
    
    func disconnect() {
        if webRTCClient.isConnected {
            webRTCClient.disconnect()
            delegate?.goBack()
        }
    }
    
    func receiveOffer(offerSDP: RTCSessionDescription){
        webRTCClient.receiveOffer(offerSDP: offerSDP, onCreateAnswer: { [unowned self] description in
            if description.type == .answer {
                let signalingData = SignalingData(sdp: description.sdp, type: .ANSWER_CALL)
                self.service.contactCenterService.sendSignalingData(chatID: currentChatID, partyID: partyID, messageID: 123, data: signalingData, with:{ result in
                })
            }
        })
    }
}

extension WebRTCViewModel {
    @objc
    private func receivedEvents(notification: Notification) {
        guard let events = notification.userInfo?[NotificationUserInfoKey.contactCenterEvents] as? [ContactCenterEvent] else {
            print("Failed to get contact center events: \(notification)")
            return
        }
        processSessionEvents(events: events)
    }
    
    private func subscribeForNotifications(completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let chatID = self.currentChatID else {
            print("Chat ID is not set")
            completion(.failure(ExampleAppError.chatIdNotSet))
            return
        }
        
        guard let deviceToken = service.deviceToken else {
            print("Device token is not set")
            completion(.failure(ExampleAppError.deviceTokenNotSet))
            return
        }
        
        if service.useFirebase {
            service.contactCenterService.subscribeForRemoteNotificationsFirebase(chatID: chatID,
                                                                                 deviceToken: deviceToken,
                                                                                 with: completion)
        } else {
            service.contactCenterService.subscribeForRemoteNotificationsAPNs(chatID: chatID,
                                                                             deviceToken: deviceToken,
                                                                             with: completion)
        }
    }
    
    private func processSessionEvents(events: [ContactCenterEvent]) {
        
        for e in events {
            
            switch e {
            case .chatSessionSignaling(partyID: _, data: let data, _, timestamp: _):
                switch data?.type {
                case .END_CALL :
                    self.delegate?.goBack()
                case .ICE_CANDIDATE:
                    let candidate = RTCIceCandidate(sdp: data?.candidate ?? "" , sdpMLineIndex: Int32(data?.sdpMLineIndex ?? "") ?? 0, sdpMid: data?.sdpMid ?? "")
                    self.webRTCClient.receiveCandidate(candidate: candidate)
                    print(">>>>>>> ICE_CANDIDATE added")
                default:
                    print("Default data type: \(data?.type)")
                }
            default:
                print("")
            }
        }
    }
    
}

