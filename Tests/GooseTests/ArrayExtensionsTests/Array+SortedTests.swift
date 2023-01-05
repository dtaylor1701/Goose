import XCTest
@testable import Goose

final class ArraySortedTests: XCTestCase {
    func testSortedAscending() throws {
        let toSort = [TestItem(id: 4), TestItem(id: 2), TestItem(id: 5), TestItem(id: 1)]
        let expected = [TestItem(id: 1), TestItem(id: 2), TestItem(id: 4), TestItem(id: 5)]
        
        XCTAssertEqual(toSort.sorted(by: \.id), expected)
    }
    
    func testSortedDescending() throws {
        let toSort = [TestItem(id: 4), TestItem(id: 2), TestItem(id: 5), TestItem(id: 1)]
        let expected = [TestItem(id: 5), TestItem(id: 4), TestItem(id: 2), TestItem(id: 1)]
        
        XCTAssertEqual(toSort.sorted(by: \.id, direction: .descending), expected)
    }
    
    func testWrapper() throws {
        let toSort = [TestItem(id: 4), TestItem(id: 2), TestItem(id: 5), TestItem(id: 1)]
        let expected = [TestItem(id: 1), TestItem(id: 2), TestItem(id: 4), TestItem(id: 5)]
        
        XCTAssertEqual(Sorted(wrappedValue: toSort, \.id).wrappedValue, expected)
    }
}

struct TestItem: Equatable {
    let id: Int
}
