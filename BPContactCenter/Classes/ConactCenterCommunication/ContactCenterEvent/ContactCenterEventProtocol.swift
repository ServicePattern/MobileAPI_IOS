//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Common type that is used to combine client and server event type objects into one sequence
/// ```
/// let events:[ContactCenterEventProtocol] = [ContactCenterClientEvent.event, ContactCenterServerEvent.event]
/// ```
/// - Tag: ContactCenterEventProtocol
protocol ContactCenterEventProtocol {
}

/// Defines API to convert from arbitrary data object to client or server event
/// ```
/// let eventData = Data() // Comes from the backend
/// let contactCenterEventDtoDecoded = try ContactCenterEventDto.decode(from: eventData).toModel()
/// ```
/// - Tag: ContactCenterEventModelConvertible
protocol ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEventProtocol
}
