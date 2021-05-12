//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// - Tag: RequestChatParameters
struct RequestChatParameters: Encodable {
    let phoneNumber: String?
    let from: String
    let parameters: [String: String]
    let userPlatform: [String: String]
    
    init(phoneNumber: String?, from: String, parameters: [String: String]) {
        #if targetEnvironment(simulator)
             let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
         #else
             var systemInfo = utsname()
             uname(&systemInfo)
        
             let machineMirror = Mirror(reflecting: systemInfo.machine)
             let identifier = machineMirror.children.reduce("") { identifier, element in
                 guard let value = element.value as? Int8, value != 0 else { return identifier }
                 return identifier + String(UnicodeScalar(UInt8(value)))
             }
         #endif
        
        self.phoneNumber = phoneNumber
        self.from = from
        self.parameters = parameters
        self.userPlatform = [
            "os": UIDevice.current.systemName + " " + UIDevice.current.systemVersion,
            "name": UIDevice.current.name,
            "manufacturer": "Apple",
            "model": UIDevice.current.model,
            "identifier": identifier
        ]
    }

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case from
        case parameters
        case userPlatform = "user_platform"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if (phoneNumber != nil) {
            try container.encode(phoneNumber, forKey: .phoneNumber)
        }
        try container.encode(from, forKey: .from)
        try container.encode(parameters, forKey: .parameters)
        var parameters = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .parameters)
        try parameters.encode(userPlatform, forKey: .userPlatform)
    }
}
