import Testing
@testable import Goose

@Suite("Array+Sorted Tests")
struct ArraySortedTests {
  @Test func sortedAscending() throws {
    let toSort = [TestItem(id: 4), TestItem(id: 2), TestItem(id: 5), TestItem(id: 1)]
    let expected = [TestItem(id: 1), TestItem(id: 2), TestItem(id: 4), TestItem(id: 5)]

    #expect(toSort.sorted(by: \.id) == expected)
  }

  @Test func sortedDescending() throws {
    let toSort = [TestItem(id: 4), TestItem(id: 2), TestItem(id: 5), TestItem(id: 1)]
    let expected = [TestItem(id: 5), TestItem(id: 4), TestItem(id: 2), TestItem(id: 1)]

    #expect(toSort.sorted(by: \.id, direction: .descending) == expected)
  }

  @Test func wrapper() throws {
    let toSort = [TestItem(id: 4), TestItem(id: 2), TestItem(id: 5), TestItem(id: 1)]
    let expected = [TestItem(id: 1), TestItem(id: 2), TestItem(id: 4), TestItem(id: 5)]

    #expect(Sorted(wrappedValue: toSort, \.id).wrappedValue == expected)
  }
}

struct TestItem: Equatable {
  let id: Int
}
