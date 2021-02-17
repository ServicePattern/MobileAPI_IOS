import XCTest
@testable import BPContactCenter

class ContactCenterTests: XCTestCase {
    let jsonDecoder = ContactCenterCommunicator.JSONCoder.decoder()
    
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
            XCTAssertEqual(eventsContainer.events.count, 9)
        } catch {
            XCTFail("\(error)")
        }
    }
}
