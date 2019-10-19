//
//  Storage.swift
//  TODOtxt
//
//  Created by subzero on 03/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

enum DataError: Error {
    case overflow, invalidFormat
}

class TextOperation: Operation {
    
    var storage: NSMutableArray = NSMutableArray(array: [Task]())
    var string: String = ""
    var grouping: Grouping = Grouping()
    
    init(storage: NSMutableArray) {
        self.storage = storage
    }
    
    override func main() {
        //sleep(1)
        
        let array = storage.compactMap { (element) -> Task? in
            return element as? Task
        }
        
        let dictionary = Dictionary(grouping: array) { (element) -> Group in
            if element.isCompleted { return .completion(value: true) }
            return grouping.group(for: element)
        }
        
        let data = dictionary.sorted { (lhs, rhs) -> Bool in
            return lhs.key.priority < rhs.key.priority
        }
        
        let mutableStr = NSMutableString()
        
        for (section, tasks) in data {
            mutableStr.append("#\(section.title):\n")
            for task in tasks {
                mutableStr.append("\(task.string)\n")
            }
            mutableStr.append("\n")
        }
        
        self.string = mutableStr.string
    }
}

class ParserOperation: Operation {
    
    var taskStorage: TaskStorage = TaskStorage()
    var string: String = ""
    
    init(string: String) {
        self.string = string
    }
    
    override func main() {
        //sleep(1)
        let parser = Parser()
        let array = parser.parse(string: string)
        self.taskStorage = TaskStorage(tasks: array)
    }
    
}

class TaskStorage {
    
    private (set) var storage: NSMutableArray   
    private(set) var mentionStorage: Bag<String> = Bag<String>()
    
    init() {
        self.storage = NSMutableArray(array: [Task]())
    }
    
    init(tasks: [Task]) {
        self.storage = NSMutableArray(array: [Task]())
        insert(tasks)
    }
    
    func reload(_ str: String) {
        let parser = Parser()
        let tasks = parser.parse(string: str)
        self.storage = NSMutableArray(array: [Task]())
        insert(tasks)
    }
    
    func insert(_ tasks: [Task]) {
        let mentions = tasks.compactMap { (task) -> String? in
            return task.hashtag
        }
        mentionStorage.insert(mentions)
        storage.addObjects(from: tasks)
    }
    
    func remove(_ tasks: [Task]) {
        let mentions = tasks.compactMap { (task) -> String? in
            return task.hashtag
        }
        mentionStorage.remove(mentions)
        for task in tasks {
            let index = storage.index(of: task)
            storage.removeObject(at: index)
        }
    }
    
}

extension TaskStorage {
    
    func string(by grouping: Grouping) -> String {
        
        let badgeFilter = Preferences.shared.badgeFilter
        
        
        let array = storage.compactMap { (element) -> Task? in
            return element as? Task
        }
        
        let dictionary = Dictionary(grouping: array) { (element) -> Group in
            if element.isCompleted { return .completion(value: true) }
            if let filter = badgeFilter, filter.evaluate(with: element) { return .pinned }
            return grouping.group(for: element)
        }
        
        let data = dictionary.sorted { (lhs, rhs) -> Bool in
            return lhs.key.priority < rhs.key.priority
        }
        
        let mutableStr = NSMutableString()
        
        for (section, tasks) in data {
            mutableStr.append("******** \(section.title) ********\n")
            for task in tasks {
                mutableStr.append("\(task.string)\n")
            }
        }
        
        let newStr = mutableStr.string
        return newStr
    }
    
    func mentions(for element: Token) -> [String] {
        return mentionStorage.storage
    }
    
}

// Data validation
extension TaskStorage {
    
    var badgeCount: Int {
        if let filter = Preferences.shared.badgeFilter {
            let result = storage.filtered(using: filter).count
            print("result = \(result)")
            return result
        } else {
            return 0
        }
    }
    
    var count: Int {
        return storage.count
    }
    
}
