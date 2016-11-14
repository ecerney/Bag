/*
* Copyright (c) 2016 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

struct Bag<Element: Hashable> {
  // 1
  fileprivate var contents: [Element: Int] = [:]

  // 2
  var uniqueCount: Int {
    return contents.count
  }

  // 3
  var totalCount: Int {
    return contents.values.reduce(0) { $0 + $1 }
  }

  // 1
  init() { }

  // 2
  init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
    for element in sequence {
      add(element)
    }
  }

  // 3
  init<S: Sequence>(_ sequence: S) where S.Iterator.Element == (key: Element, value: Int) {
    for (element, count) in sequence {
      add(element, occurrences: count)
    }
  }

  // 1
  mutating func add(_ member: Element, occurrences: Int = 1) {
    // 2
    precondition(occurrences > 0, "Can only add a positive number of occurrences")

    // 3
    if let currentCount = contents[member] {
      contents[member] = currentCount + occurrences
    } else {
      contents[member] = occurrences
    }
  }

  mutating func remove(_ member: Element, occurrences: Int = 1) {
    // 1
    guard let currentCount = contents[member], currentCount >= occurrences else {
      preconditionFailure("Removed non-existent elements")
    }

    // 2
    precondition(occurrences > 0, "Can only remove a positive number of occurrences")

    // 3
    if currentCount > occurrences {
      contents[member] = currentCount - occurrences
    } else {
      contents.removeValue(forKey: member)
    }
  }
}

extension Bag: CustomStringConvertible {
  var description: String {
    return String(describing: contents)
  }
}

extension Bag: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension Bag: ExpressibleByDictionaryLiteral {
  init(dictionaryLiteral elements: (Element, Int)...) {
    // The map converts elements to the "named" tuple the initializer expects.
    self.init(elements.map { (key: $0.0, value: $0.1) })
  }
}

extension Bag: Sequence {
  // 1
  typealias Iterator = AnyIterator<(element: Element, count: Int)>

  func makeIterator() -> Iterator {
    // 2
    var iterator = contents.makeIterator()

    // 3
    return AnyIterator {
      return iterator.next()
    }
  }
}

extension Bag: Collection {
  // 1
  typealias Index = BagIndex<Element>

  var startIndex: Index {
    // 2.1
    return BagIndex(contents.startIndex)
  }

  var endIndex: Index {
    // 2.2
    return BagIndex(contents.endIndex)
  }

  subscript (position: Index) -> Iterator.Element {
    precondition((startIndex ..< endIndex).contains(position), "out of bounds")
    // 3
    let dictionaryElement = contents[position.index]
    return (element: dictionaryElement.key, count: dictionaryElement.value)
  }

  func index(after i: Index) -> Index {
    // 4
    return Index(contents.index(after: i.index))
  }
}

// 1
struct BagIndex<Element: Hashable> {
  // 2
  fileprivate let index: DictionaryIndex<Element, Int>

  // 3
  fileprivate init(_ dictionaryIndex: DictionaryIndex<Element, Int>) {
    self.index = dictionaryIndex
  }
}

extension BagIndex: Comparable {
  static func == (lhs: BagIndex, rhs: BagIndex) -> Bool {
    return lhs.index == rhs.index
  }

  static func < (lhs: BagIndex, rhs: BagIndex) -> Bool {
    return lhs.index < rhs.index
  }
}

var shoppingCart = Bag<String>()
shoppingCart.add("Banana")
shoppingCart.add("Orange", occurrences: 2)
shoppingCart.add("Banana")
shoppingCart.remove("Orange")

precondition("\(shoppingCart)" == "\(shoppingCart.contents)", "Expected bag description to match its contents description")

let dataArray = ["Banana", "Orange", "Banana"]
let dataDictionary = ["Banana": 2, "Orange": 1]
let dataSet: Set = ["Banana", "Orange", "Banana"]

var arrayBag = Bag(dataArray)
precondition(arrayBag.contents == dataDictionary, "Expected arrayBag contents to match \(dataDictionary)")

var dictionaryBag = Bag(dataDictionary)
precondition(dictionaryBag.contents == dataDictionary, "Expected dictionaryBag contents to match \(dataDictionary)")

var setBag = Bag(dataSet)
precondition(setBag.contents == ["Banana": 1, "Orange": 1], "Expected setBag contents to match \(["Banana": 1, "Orange": 1])")

var arrayLiteralBag: Bag = ["Banana", "Orange", "Banana"]
precondition(arrayLiteralBag.contents == dataDictionary, "Expected arrayLiteralBag contents to match \(dataDictionary)")

var dictionaryLiteralBag: Bag = ["Banana": 2, "Orange": 1]
precondition(dictionaryLiteralBag.contents == dataDictionary, "Expected dictionaryLiteralBag contents to match \(dataDictionary)")

for element in shoppingCart {
  print(element)
}

for (element, count) in shoppingCart {
  print("Element: \(element), Count: \(count)")
}

// Find all elements with a count greater than 1
let moreThanOne = shoppingCart.filter { $0.1 > 1 }
moreThanOne
precondition(moreThanOne.first!.element == "Banana" && moreThanOne.first!.count == 2, "Expected moreThanOne contents to be [(\"Banana\", 2)]")

// Get an array of all elements without counts
let itemList = shoppingCart.map { $0.0 }
itemList
precondition(itemList == ["Orange", "Banana"], "Expected itemList contents to be [\"Orange\", \"Banana\"]")

// Get the total number of items in the bag
let numberOfItems = shoppingCart.reduce(0) { $0 + $1.1 }
numberOfItems
precondition(numberOfItems == 3, "Expected numberOfItems contents to be 3")

// Get a sorted array of elements by their count in decending order
let sorted = shoppingCart.sorted { $0.0 < $1.0 }
sorted
precondition(sorted.first!.element == "Banana" && moreThanOne.first!.count == 2, "Expected sorted contents to be [(\"Banana\", 2), (\"Orange\", 1)]")

// Get the first item in the bag
let firstItem = shoppingCart.first
precondition(firstItem!.element == "Orange" && firstItem!.count == 1, "Expected first item of shopping cart to be (\"Orange\", 1)")

// Check if the bag is empty
let isEmpty = shoppingCart.isEmpty
precondition(isEmpty == false, "Expected shopping cart to not be empty")

// Get the number of unique items in the bag
let uniqueItems = shoppingCart.count
precondition(uniqueItems == 2, "Expected shoppingCart to have 2 unique items")

// Find the first item with an element of "Banana"
let bananaIndex = shoppingCart.indices.first { shoppingCart[$0].element == "Banana" }!
let banana = shoppingCart[bananaIndex]
precondition(banana.element == "Banana" && banana.count == 2, "Expected banana to have value (\"Banana\", 2)")

// 1
let fruitBasket = Bag(dictionaryLiteral: ("Apple", 5), ("Orange", 2), ("Pear", 3), ("Banana", 7))

// 2
let fruitSlice = fruitBasket.dropFirst() // No pun intended ;]

// 3
if let fruitMinIndex = fruitSlice.indices.min(by: { fruitSlice[$0] > fruitSlice[$1] }) {
  // 4
  let minFruitFromSlice = fruitSlice[fruitMinIndex]
  let minFruitFromBasket = fruitBasket[fruitMinIndex]
}
