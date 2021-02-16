//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

struct HttpRequestDefaultParameters: Encodable {
    /// Identifies your contact center. It corresponds to the domain name of your contact center that you see in the upper right corner of the Contact Center Administrator application after login.
    let tenantUrl: String
}
