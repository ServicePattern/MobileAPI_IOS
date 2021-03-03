//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

extension URLRequest {
    mutating public func set(headerFields: [String: String]?) {
        headerFields?.forEach { self.setValue($0.value, forHTTPHeaderField: $0.key) }
    }
}
