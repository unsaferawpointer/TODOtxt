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
    var grouping: Grouping = .commonDateStyle
    
    init(storage: NSMutableArray) {
        self.storage = storage
    }
    
    override func main() {
        //sleep(1)
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
            mutableStr.append("## \(section.title)\n")
            for task in tasks {
                mutableStr.append("\(task.string)\n")
            }
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

class MentionStorage {
    
    private(set) var autocompletions: Set<Element> = [.project, .context]
    private(set) var storage: [Element: Bag<String>] = [:]
    
    init() {
        for element in autocompletions {
            storage[element] = Bag<String>.init()
        }
    }
    
    func mentions(for element: Element) -> [String] {
        return storage[element]?.sorted ?? []
    }
    
    
    /// FIX ME inout
    func insert(from todos: [Task]) {
        for element in autocompletions {
            let array = todos.compactMap { (todo) -> String? in
                return todo.key(by: element)
            }
            storage[element]?.insert(array)
        }
    }
    
    /// FIX ME inout
    func remove(from todos: [Task]) {
        for element in autocompletions {
            let array = todos.compactMap { (todo) -> String? in
                return todo.key(by: element)
            }
            storage[element]?.remove(array)
        }
    }
    
}

enum Group: Hashable {
    
    case mention(value: String)
    case date(value: String)
    case completion(value: Bool)
    case pinned
    case none
    
    var title: String {
        switch self {
        case .mention(let value):
            return String(value.dropFirst(2))
        case .completion(let value):
            return value ? "completed" : "uncompleted"
        case .date(let value):
            return String(value.dropFirst(4))
        case .pinned:
            return "pinned"
        case .none:
            return "w/o"
        }
    }
    
    var priority: String {
        switch self {
        case .pinned:
            return "0"
        case .mention(let value):
            return value
        case .date(let value):
            return value
        case .none:
            return "2"
        case .completion(let value):
            return value ? "3" : "1"
        }
    }
    
}

enum Grouping {
    case project, context, priority, date
    case commonDateStyle
    case status
    
    func group(for task: Task) -> Group {
        switch self {
        case .project:
            if let key = task.project {
                return .mention(value: "1_+\(key)")
            }
        case .context:
            if let key = task.context {
                return .mention(value: "1_@\(key)")
            }
        case .priority:
            if let key = task.priority {
                return .mention(value: "1_\(key)")
            }
        case .date:
            if let key = task.dueDate?.description {
                return .mention(value: "1_due:\(key)")
            }
        case .commonDateStyle:
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            guard let date = task.dueDate as Date? else { return .none }
            
            
            let calendar = NSCalendar.current
            let today = Date()
            let tomorrow = NSCalendar.current.date(byAdding: .day, value: 1, to: today)!
            
            if calendar.compare(today, to: date, toGranularity: .day) == .orderedDescending {
                return .date(value: "1_0_overdue")
            } else if calendar.compare(today, to: date, toGranularity: .day) == .orderedSame {
                return .date(value: "1_1_today")
            } else if calendar.compare(tomorrow, to: date, toGranularity: .day) == .orderedSame {
                return .date(value: "1_2_tomorrow")
            } else if calendar.compare(today, to: date, toGranularity: .weekOfYear) == .orderedSame {
                return .date(value: "1_3_current week")
            } else if calendar.compare(today, to: date, toGranularity: .month) == .orderedSame {
                return .date(value: "1_4_current month")
            } else if calendar.compare(today, to: date, toGranularity: .year) == .orderedSame {
                return .date(value: "1_5_current year")
            } else {
                return .date(value: "1_6_later")
            }
        
        case .status:
            return .completion(value: task.isCompleted)
        }
        
        return .none
    }
}


class TaskStorage {
    
    private var comparator: Comparator = Comparator()
    private (set) var storage: NSMutableArray   
    private var mentionStorage: MentionStorage = MentionStorage()
    
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
        mentionStorage.insert(from: tasks)
        storage.addObjects(from: tasks)
    }
    
    func remove(_ tasks: [Task]) {
        mentionStorage.remove(from: tasks)
        for task in tasks {
            let index = storage.index(of: task)
            storage.removeObject(at: index)
        }
    }
    
}

extension TaskStorage {
    
    func remove(by filter: NSPredicate) {
        let removed = storage.filtered(using: filter)
        for task in removed as! [Task] {
            mentionStorage.remove(from: [task])
            storage.remove(task)
        }
    }
    
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
    
    var string: String {
        let empty = NSMutableString()
        // WARNING
        let sorted = storage
        let mutStr = sorted.reduce(into: empty) { (result, todo) in
            return result.append("\((todo as! Task).string)\n")
        }
        return mutStr.string
    }
    
    func string(by filter: NSPredicate) -> String {
        // WARNING
        //let filtered = storage.filter(filter.contains(_:))
        let filtered = storage.filtered(using: filter) as! [Task]
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
