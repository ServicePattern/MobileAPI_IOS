//
//  ViewController.swift
//  BPContactCenter
//
//  Created by BrightPattern on 02/12/2021.
//  Copyright (c) 2021 BrightPattern. All rights reserved.
//

import UIKit
import BPContactCenter

class Communicating {
}

extension DefaultStringInterpolation {
    /// Allows to print optional values without a prefix.
    /// ```
    /// let x: Int? = 1
    /// print("\(x)") // > 1
    /// ```
    mutating func appendInterpolation<T>(_ optional: T?) {
        appendInterpolation(String(describing: optional))
    }
}

class ViewController: UIViewController {
    var contactCenterService: ContactCenterCommunicating?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let baseURL = URL(string: "http://alvm.bugfocus.com")!
        let tenantURL = URL(string: "devs.alvm.bugfocus.com")!
        let appID = "apns"
        let clientID = "D3577669-EB4B-4565-B9C6-27DD857CE8E5"
        //let clientID = "817AB6B9-75E8-4CCB-A042-C78E8EA45FF6"

        contactCenterService = ContactCenterCommunicator(baseURL: baseURL, tenantURL: tenantURL, appID: appID, clientID: clientID)

        contactCenterService?.checkAvailability { [weak self] serviceAvailabilityResult in
            switch serviceAvailabilityResult {
            case .success(let serviceAvailability):
                print("Chat is \(serviceAvailability.chat)")
                if serviceAvailability.chat == .available {
                    self?.contactCenterService?.requestChat(phoneNumber: "12345", from: "54321", parameters: [:]) { [weak self] chatPropertiesResult in
                        switch chatPropertiesResult {
                        case .success(let chatProperties):
                            print("Chat properties: \(chatProperties)")
                            self?.contactCenterService?.getChatHistory(chatID: chatProperties.chatID) { eventsResult in
                                switch eventsResult {
                                case .success(let events):
                                    print("Events: \(events)")
                                    
                                    for e in events {
                                        switch e {
                                        case .chatSessionMessage(let messageID, let partyID, let message, let timestamp):
                                            print("\(timestamp): message: \(message) from party \(partyID)")
                                            self?.chatMessageDelivered(chatID: chatProperties.chatID, messageID: messageID)
                                            self?.chatMessageRead(chatID: chatProperties.chatID, messageID: messageID)
                                        default:()
                                        }
                                    }
                                    
                                    self?.sendChatMessage(chatID: chatProperties.chatID, message: "Hello")
                                    self?.disconnectChat(chatID: chatProperties.chatID)
                                    self?.endChat(chatID: chatProperties.chatID)
                                    
                                case .failure(let error):
                                    print("Failed to getChatHistory: \(error)")
                                }
                            }
                        case .failure(let error):
                            print("\(error)")
                        }
                    }
                }
            case .failure(let error):
                print("Failed to check availability: \(error)")
            }
        }
    }

    private func sendChatMessage(chatID: String, message: String) {
        self.contactCenterService?.sendChatMessage(chatID: chatID, message: "Hello") { chatMessageResult in
            switch chatMessageResult {
            case .success(let messageID):
                print("MessageID: \(messageID)")

            case .failure(let error):

                print("Failed to send chat message: \(error)")
            }
        }
    }

    private func chatMessageDelivered(chatID: String, messageID: String) {
        self.contactCenterService?.chatMessageDelivered(chatID: chatID, messageID: messageID) { result in
            switch result {
            case .success(_):
                print("chatMessageDelivered confirmed")
            case .failure(let error):
                print("chatMessageDelivered error: \(error)")
            }
        }
    }

    private func chatMessageRead(chatID: String, messageID: String) {
        self.contactCenterService?.chatMessageRead(chatID: chatID, messageID: messageID) { result in
            switch result {
            case .success(_):
                print("chatMessageRead confirmed")
            case .failure(let error):
                print("chatMessageRead error: \(error)")
            }
        }
    }

    private func disconnectChat(chatID: String) {
        self.contactCenterService?.disconnectChat(chatID: chatID) { result in
            switch result {
            case .success(_):
                print("disconnectChat confirmed")
            case .failure(let error):
                print("disconnectChat error: \(error)")
            }
        }
    }

    private func endChat(chatID: String) {
        self.contactCenterService?.endChat(chatID: chatID) { result in
            switch result {
            case .success(_):
                print("endChat confirmed")
            case .failure(let error):
                print("endChat error: \(error)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: ContactCenterEventsDelegating {
    func chatSessionEvents(result: Result<[ContactCenterEvent], Error>) {
        switch result {
        case .success(let events):
            print("Received events: \(events.count) confirmed")
        case .failure(let error):
            print("chatSessionEvents failed: \(error)")
        }
    }
}
