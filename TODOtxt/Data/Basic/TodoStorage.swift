//
//  TodoStorage.swift
//  TODOtxt
//
//  Created by subzero on 03/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

enum DataError: Error {
    case overflow, invalidFormat
}

class MentionStorage {
    
    private(set) var autocompletions: Set<Element> = [.project, .context]
    private(set) var storage: [Element: Bag<String>] = [:]
    
    init() {
        for element in autocompletions {
            storage[element] = Bag<String>()
        }
    }
    
    func mentions(for element: Element) -> [String] {
        return storage[element]?.backingStorage._elements ?? [String]()
    }
    
    
    /// FIX ME inout
    func insert(from todos: [ToDo]) {
        for element in autocompletions {
            let array = todos.compactMap { (todo) -> String? in
                return todo.key(by: element)
            }
            storage[element]?.insert(array)
        }
    }
    
    /// FIX ME inout
    func remove(from todos: [ToDo]) {
        for element in autocompletions {
            let array = todos.compactMap { (todo) -> String? in
                return todo.key(by: element)
            }
            storage[element]?.remove(array)
        }
    }
    
}

class TodoStorage {
    
    // WARNING UNUSED TODOS_LIMIT
    let CHARACTERS_LIMIT = 4_000
    let TODOS_LIMIT = 150
    
    private var comparator: Comparator = Comparator()
    private var storage: [ToDo] = []
    
    private var mentionStorage: MentionStorage = MentionStorage()
    
    init() {
        
    }
    
    func reload(_ data: Data) throws {
        guard let str = String(data: data, encoding: .utf8) else { throw DataError.invalidFormat}
        guard str.count <= CHARACTERS_LIMIT else { throw DataError.overflow }
        
        let parser = Parser()
        performOperation(inserted: parser.parse(str), removed: [])
    }
    
    func performOperation(inserted: [ToDo], removed: [ToDo]) {
        mentionStorage.remove(from: removed)
        mentionStorage.insert(from: inserted)
        storage += inserted
        for todo in removed {
            let index = storage.firstIndex(of: todo)!
            storage.remove(at: index)
        }
    }
    
    
}

extension TodoStorage {
    
    var string: String {
        let empty = NSMutableString()
        let sorted = storage.sorted(by: comparator.compare(_:_:))
        let mutStr = sorted.reduce(into: empty) { (result, todo) in
            return result.append("\(todo.string)\n")
        }
        return mutStr.string
    }
    
    func string(by filter: Filter) -> String {
        let filtered = storage.filter(filter.contains(_:))
        let sorted = filtered.sorted(by: comparator.compare(_:_:))
        let empty = NSMutableString()
        let mutStr = sorted.reduce(into: empty) { (result, todo) in
            return result.append("\(todo.string)\n")
        }
        return mutStr.string
    }
    
    var data: Data {
        return string.data(using: .utf8) ?? Data()
    }
    
    func mentions(for element: Element) -> [String] {
        return mentionStorage.mentions(for: element)
    }
    
}

// Data validation
extension TodoStorage {
    
    var count: Int {
        return storage.count
    }
    
    func shouldChange(with delta: Int) -> Bool {
        guard delta > 0 else { return true }
        
        return count + delta <= CHARACTERS_LIMIT
    }
    
}
