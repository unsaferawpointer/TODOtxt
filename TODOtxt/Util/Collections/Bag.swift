//
//  Bag.swift
//  TODO txt
//
//  Created by subzero on 25/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation


public struct Bag<Element: Hashable & Comparable > {
    
    private(set) var storage: [Element] = []
    fileprivate var contents: [Element: Int] = [:]
    
    subscript(position: Int) -> Element {
        return storage[position]
    }
    
    var sorted: [Element] {
        return storage.sorted()
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
    public mutating func insert(_ object: Element, occurrences: Int = 1) {
        
        precondition(occurrences > 0, "Can only add a positive number of occurrences")
        
        if let currentCount = contents[object] {
            contents[object] = currentCount + occurrences
        } else {
            contents[object] = occurrences
            storage.append(object)
        }
        
    }
    
    ///If anObject is present in the set, decrements the count associated with it and return nil. If the count is decremented to 0, anObject is removed from the set and return anObject.
    public mutating func remove(_ object: Element, occurrences: Int = 1) {
        guard let currentCount = contents[object], currentCount >= occurrences else {
            preconditionFailure("Removed non-existent elements")
        }
        
        precondition(occurrences > 0, "Can only remove a positive number of occurrences")
        
        if currentCount > occurrences {
            contents[object] = currentCount - occurrences
        } else {
            contents.removeValue(forKey: object)
            if let index = storage.firstIndex(of: object) {
                storage.remove(at: index)
            } else {
                fatalError("The storage dont contains a object")
            }
            
        }
        
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
        storage.removeAll()
    }
    
}


