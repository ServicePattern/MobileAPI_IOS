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
                                    self?.sendChatMessage(chatID: chatProperties
                                                            .chatID, message: "Hello")
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

