//
//  Bag.swift
//  TODO txt
//
//  Created by subzero on 25/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation


public struct Bag<Element: Hashable & Comparable > {
    
    private(set) var backingStorage: SortedArray<Element>
    fileprivate var contents: [Element: Int]
    
    fileprivate var _changed: Set<Element> = []
    fileprivate var _observeChanges: Bool = false
    
    subscript(position: Int) -> Element {
        return backingStorage[position]
    }
    
    var uniqueCount: Int {
        return contents.count
    }
    
    var totalCount: Int {
        return contents.values.reduce(0) { $0 + $1 }
    }
    
    func count(for object: Element) -> Int {
        return contents[object] ?? 0
    }
    
    ///Start accumulate a changes.
    mutating func beginChange() {
        self._observeChanges = true
        self.backingStorage.beginChange()
    }
    
    ///End accumulate a changes.
    mutating func endChange() {
        self._observeChanges = false
        self.backingStorage.endChange()
        self._changed = []
        
    }
    
    public var changes: [OperationType: IndexSet] {
        var result = backingStorage.changes
        print("Bag class _changed = \(_changed)")
        for object in _changed {
            if let index = backingStorage._elements.firstIndex(of: object) {
                print("index = \(index)")
                result[.update]!.insert(index)
            }
        }
        print("Bag class update changes = \(result[.update])")
        return result
    }
    
    // WARNING COMPARATOR
    init() { 
        let comparator = { (lhs: Element, rhs: Element )in lhs < rhs }
        self.backingStorage = SortedArray<Element>(comparator: comparator)
        self.contents = [:]
    }
    
    
    public mutating func insert(_ objects: [Element]) {
        for object in objects {
            insert(object)
        }
    }
    
    public mutating func remove(_ objects: [Element]) {
        for object in objects {
            remove(object)
        }
    }
    
    
    
    ///If anObject is present in the bag, increments the count associated with it and return nil. Otherwise, insert anObject to the bag  and return anObject.
    public mutating func insert(_ object: Element, occurrences: Int = 1) -> (object: Element, at: Int)? {
        
        precondition(occurrences > 0, "Can only add a positive number of occurrences")
        
        if let currentCount = contents[object] {
            contents[object] = currentCount + occurrences
            if _observeChanges { _changed.insert(object) }
        } else {
            contents[object] = occurrences
            let index = backingStorage.insert(object)
            return (object: object, at: index)
        }
        
        return nil
    }
    
    ///If anObject is present in the set, decrements the count associated with it and return nil. If the count is decremented to 0, anObject is removed from the set and return anObject.
    public mutating func remove(_ object: Element, occurrences: Int = 1) -> Element? {
        
        guard let currentCount = contents[object], currentCount >= occurrences else {
            preconditionFailure("Removed non-existent elements")
        }
        
        precondition(occurrences > 0, "Can only remove a positive number of occurrences")
        
        if currentCount > occurrences {
            contents[object] = currentCount - occurrences
            if _observeChanges { _changed.insert(object) }
        } else {
            contents.removeValue(forKey: object)
            backingStorage.remove(object)
            return object
        }
        
        return nil
    }
    
    /*
     /// Adds the elements of the given bag to the bag 
     mutating func formUnion(other bag: Bag) {
     contents.merge(bag.contents) { $0 + $1 }
     }
     */
    /// Removes all elements from the bag
    public mutating func removeAll() {
        contents.removeAll()
        backingStorage.removeAll()
    }
    
}


