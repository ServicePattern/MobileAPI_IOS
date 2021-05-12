//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation
import BPMobileMessaging

protocol HelpRequestUpdatable: class {
    func update()
    func showChat()
}

class HelpRequestViewModel {
    let service: ServiceDependencyProtocol
    var currentChatID: String?
    let bottomSpace = CGFloat(105)
    var isChatAvailable: Bool = false {
        didSet {
            delegate?.update()
        }
    }
    var serverVersion: String = "" {
        didSet {
//            delegate?.update()
        }
    }
    var isRequestInProgress: Bool = false {
        didSet {
            delegate?.update()
        }
    }
    weak var delegate: HelpRequestUpdatable?

    init(service: ServiceDependencyProtocol) {
        self.service = service

        getServerVersion()
        checkChatAvailability()
    }

    deinit {
    }

    func helpMePressed(problemDescription: String, caseNumber: String) {
        requestChat(problemDescription: problemDescription, caseNumber: caseNumber)
    }
}

extension HelpRequestViewModel {
    private func getServerVersion() {
        service.contactCenterService.getVersion { [weak self] serviceVersion in
            DispatchQueue.main.async {
                switch serviceVersion {
                case .success(let version):
                    print("Server version is \(version.serverVersion)")
                    self?.serverVersion = version.serverVersion
                case .failure(let error):
                    print("Failed to obtain server version: \(error)")
                }
            }
        }
    }
    private func checkChatAvailability() {
        isRequestInProgress = true
        service.contactCenterService.checkAvailability { [weak self] serviceAvailabilityResult in
            DispatchQueue.main.async {
                self?.isRequestInProgress = false
                switch serviceAvailabilityResult {
                case .success(let serviceAvailability):
                    print("Chat is \(serviceAvailability.chat)")
                    self?.isChatAvailable = serviceAvailability.chat == .available
                case .failure(let error):
                    print("Failed to check availability: \(error)")
                }
            }
        }
    }
    private func requestChat(problemDescription: String, caseNumber: String) {
        isRequestInProgress = true
        let phoneNumber = service.phoneNumber
        let firstName = service.firstName
        let lastName = service.lastName
        service.contactCenterService.requestChat(phoneNumber: "12345",
                                                 from: phoneNumber,
                                                 parameters:
                                                    ["email": "mobilecustomer@example.com",
                                                     "first_name": firstName,
                                                     "last_name": lastName,
                                                     "caseNumber": caseNumber,
                                                     "problem_description": problemDescription]) { [weak self] chatPropertiesResult in
            DispatchQueue.main.async {
                self?.isRequestInProgress = false
                switch chatPropertiesResult {
                case .success(let chatProperties):
                    print("Chat properties: \(chatProperties)")
                    self?.currentChatID = chatProperties.chatID
                    self?.delegate?.showChat()
                case .failure(let error):
                    print("\(error)")
                }
            }
        }
    }
}
