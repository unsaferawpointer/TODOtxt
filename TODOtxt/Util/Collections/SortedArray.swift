//
//  SortedArray.swift
//  TODO txt
//
//  Created by subzero on 25/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

public enum OperationType {
    case insert
    case update
    case remove
}

struct SortedArray<Element: Hashable> {
    
    public typealias Comparator<Element> = (Element, Element) -> Bool
    
    fileprivate var _removed: Set<Element> = []
    fileprivate var _inserted: Set<Element> = []
    
    fileprivate var _buffer: [Element] = []
    fileprivate var _observeChanges: Bool = false
    
    public var changes: [OperationType: IndexSet] {
        
        var removed = IndexSet()
        // WARNING HAS NO BINARY SEARCH
        for object in _removed {
            if let index = _buffer.firstIndex(of: object) { 
                removed.insert(index)
            } else {
                fatalError("Object not found in _buffer") 
            }
        }
        
        var inserted = IndexSet()
        for object in _inserted {
            if let index = anyIndex(of: object) {
                inserted.insert(index)
            } else {
                print("object in inserted = \(object)")
                print("_elements = \(_elements)")
                fatalError("Object not found in _elements")
            }
        }
        
        let updated = removed.intersection(inserted)
        removed.subtract(updated)
        inserted.subtract(updated)
        
        return [.insert: inserted, .remove: removed, .update: updated]
    }
    
    private(set) var _elements: [Element] = []
    /// The predicate that determines the array's sort order.
    fileprivate let areInIncreasingOrder: Comparator<Element>
    
    
    
    subscript(position: Index) -> Element {
        return _elements[position]
    }
    
    
    ///Start accumulate a changes.
    mutating func beginChange() {
        self._buffer = _elements
        self._observeChanges = true
    }
    
    ///End accumulate a changes.
    mutating func endChange() {
        self._buffer = []
        self._inserted = []
        self._removed = []
        self._observeChanges = false
    }
    
    init(comparator: @escaping Comparator<Element>) { 
        self.areInIncreasingOrder = comparator
    }
    
    /// Removes all elements from the collection
    public mutating func removeAll() {
        self._buffer = []
        self._inserted = []
        self._removed = []
        self._elements = []
    }
    
}

fileprivate enum Match<Index: Comparable> {
    case found(at: Index)
    case notFound(insertAt: Index)
}


extension Range where Bound == Int {
    
    var middle: Int? {
        guard !isEmpty else { return nil }
        return lowerBound + count / 2
    }
}

extension SortedArray {
    
    public typealias Index = Int
    
    public var startIndex: Index { return _elements.startIndex }
    public var endIndex: Index { return _elements.endIndex }
    
    public func index(after i: Index) -> Index {
        return _elements.index(after: i)
    }
    
    fileprivate func compare(_ lhs: Element, _ rhs: Element) -> Foundation.ComparisonResult {
        if areInIncreasingOrder(lhs, rhs) {
            return .orderedAscending
        } else if areInIncreasingOrder(rhs, lhs) {
            return .orderedDescending
        } else {
            // If neither element comes before the other, they _must_ be
            // equal, per the strict ordering requirement of `areInIncreasingOrder`.
            return .orderedSame
        }
    }
    /// Returns an arbitrary index where the specified value appears in the collection.
    /// Like `index(of:)`, but without the guarantee to return the *first* index
    /// if the array contains duplicates of the searched element.
    ///
    /// Can be slightly faster than `index(of:)`.
    public func anyIndex(of element: Element) -> Index? {
        switch search(for: element) {
        case let .found(at: index): return index
        case .notFound(insertAt: _): return nil
        }
    }
    
    /// The index where `newElement` should be inserted to preserve the array's sort order.
    fileprivate func insertionIndex(for newElement: Element) -> Index {
        switch search(for: newElement) {
        case let .found(at: index): return index
        case let .notFound(insertAt: index): return index
        }
    }
    /// Searches the array for `element` using binary search.
    ///
    /// - Returns: If `element` is in the array, returns `.found(at: index)`
    ///   where `index` is the index of the element in the array.
    ///   If `element` is not in the array, returns `.notFound(insertAt: index)`
    ///   where `index` is the index where the element should be inserted to 
    ///   preserve the sort order.
    ///   If the array contains multiple elements that are equal to `element`,
    ///   there is no guarantee which of these is found.
    ///
    /// - Complexity: O(_log(n)_), where _n_ is the size of the array.
    fileprivate func search(for element: Element) -> Match<Index> {
        return search(for: element, in: startIndex ..< endIndex)
    }
    
    fileprivate func search(for element: Element, in range: Range<Index>) -> Match<Index> {
        guard let middle = range.middle else { return .notFound(insertAt: range.upperBound) }
        switch compare(element, self[middle]) {
        case .orderedDescending:
            return search(for: element, in: index(after: middle)..<range.upperBound)
        case .orderedAscending:
            return search(for: element, in: range.lowerBound..<middle)
        case .orderedSame:
            return .found(at: middle)
        }
    }
    
    /// Inserts a new element into the array, preserving the sort order.
    ///
    /// - Returns: the index where the new element was inserted.
    /// - Complexity: O(_n_) where _n_ is the size of the array. O(_log n_) if the new
    /// element can be appended, i.e. if it is ordered last in the resulting array.
    @discardableResult
    public mutating func insert(_ newElement: Element) -> Index {
        let index = insertionIndex(for: newElement)
        // This should be O(1) if the element is to be inserted at the end,
        // O(_n) in the worst case (inserted at the front).
        _elements.insert(newElement, at: index)
        if _observeChanges { _inserted.insert(newElement)}
        return index
    }
    
    /*
     // Removes and returns the element at the specified position.
     ///
     /// - Parameter index: The position of the element to remove. `index` must be a valid index of the array.
     /// - Returns: The element at the specified index.
     /// - Complexity: O(_n_), where _n_ is the length of the array.
     @discardableResult
     public mutating func remove(at index: Int) -> Element {
     return _elements.remove(at: index)
     }*/
    
    public mutating func remove(_ object: Element) -> Index? {
        if let index = anyIndex(of: object) {
            if _observeChanges { _removed.insert(object) }
            _elements.remove(at: index)
            return index
        }
        return nil
    }
}


