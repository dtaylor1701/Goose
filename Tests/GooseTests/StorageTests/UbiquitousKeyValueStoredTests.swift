import XCTest
@testable import Goose

final class UbiquitousKeyValueStoredTests: XCTestCase {
    func testDefaultValue() {
        var wrapper = UbiquitousKeyValueStored<Int>("test", defaultValue: 1)
        
        wrapper.wrappedValue = nil
        
        XCTAssertEqual(1, wrapper.wrappedValue)
    }
    
    func testNilDefaultValue() {
        var wrapper = UbiquitousKeyValueStored<Int>("test", defaultValue: nil)
        
        wrapper.wrappedValue = nil
        
        XCTAssertNil(wrapper.wrappedValue)
    }
    
    func testArray() {
        var wrapper = UbiquitousKeyValueStored<[Int]>("test", defaultValue: nil)
        
        wrapper.wrappedValue = [1,2,3]
        
        XCTAssertEqual([1,2,3], wrapper.wrappedValue)
    }
}
