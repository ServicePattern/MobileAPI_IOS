//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

private struct ContactCenterEventTypeContainerDto: Decodable {
    let event: ContactCenterEventTypeDto
}

/// - Tag: ContactCenterEventsContainerDto
struct ContactCenterEventsContainerDto: Decodable {
    let events: [ContactCenterEventProtocol]

    enum CodingKeys: String, CodingKey {
        case events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var eventsContainer = try container.nestedUnkeyedContainer(forKey: .events)
        var events = [ContactCenterEventProtocol]()
        var eventDtoTypes = [ContactCenterEventTypeDto]()
        guard let count = eventsContainer.count else {
            self.events = []
            return
        }
        events.reserveCapacity(count)
        eventDtoTypes.reserveCapacity(count)
        while !eventsContainer.isAtEnd {
            // The backend sends a collection of event of different types
            // To decode each item to a specific type use JSONEncoder to get data
            // 1. Try to infer a specific Dto type based on the "event" property
            let eventType = try eventsContainer.decode(ContactCenterEventTypeContainerDto.self).event
            eventDtoTypes.append(eventType)
        }
        eventsContainer = try container.nestedUnkeyedContainer(forKey: .events)
        self.events = eventDtoTypes.compactMap {
            do {
                return try $0.decodeDto(from: eventsContainer.superDecoder()).toModel()
            } catch {
                log.error("\(error)")
                return nil
            }
        }
    }
}

extension ContactCenterEventsContainerDto {
    func toModel() -> ContactCenterEventContainer {
        let clientEvents = events.compactMap { $0 as? ContactCenterClientEvent }
        let serverEvents = events.compactMap { $0 as? ContactCenterServerEvent }

        return ContactCenterEventContainer(clientEvents: clientEvents, serverEvents: serverEvents)
    }
}
