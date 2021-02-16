//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

/// Container for client and server events
/// - Tag: ContactCenterEvents
public struct ContactCenterEventContainer {
    let clientEvents: [ContactCenterClientEvent]
    let serverEvents: [ContactCenterServerEvent]
}
