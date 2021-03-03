import XCTest
@testable import BPMobileMessaging

class ContactCenterTests: XCTestCase {
    let jsonDecoder = ContactCenterCommunicator.JSONCoder.decoder()
    let jsonEncoder = ContactCenterCommunicator.JSONCoder.encoder()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func eventsFixtureData() -> Data {
        let testBundle = Bundle(for: type(of: self))
        guard let fixtureFileURL = testBundle.url(forResource: "eventsFixture", withExtension: "txt") else {
            // file does not exist
            XCTFail("Failed to load fixture file")
            return Data()
        }
        do {
            return try Data(contentsOf: fixtureFileURL)
        } catch {
            XCTFail("Failed to load fixture file: \(error)")
            return Data()
        }
    }
    
    func testEventsDecoding() {
        do {
            let eventsContainer = try jsonDecoder.decode(ContactCenterEventsContainerDto.self, from: eventsFixtureData())
            print("\(eventsContainer.events)")
            XCTAssertEqual(eventsContainer.events.count, 17)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testEventsEncoding() {
        do {
            let eventsContainer = ContactCenterEventsContainerDto(events: [.chatSessionEnd, .chatSessionDisconnect, .chatSessionInactivityTimeout(message: "123123", timestamp: Date()), .chatSessionMessage(messageID: "sdsdfsdf", partyID: "2342342", message: "sfdsfsf", timestamp: Date()),
                                                                           .chatSessionLocation(partyID: "111", url: "urkl1", latitude: 123.456, longitude: 321.654, timestamp: Date())])
            let encodedEventsContainer = try jsonEncoder.encode(eventsContainer)
            print("\(String(decoding: encodedEventsContainer, as: UTF8.self))")
            XCTAssertGreaterThan(encodedEventsContainer.count, 0)
        } catch {
            XCTFail("\(error)")
        }
    }
}
