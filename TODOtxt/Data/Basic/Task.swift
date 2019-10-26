//
//  ToDo.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum TaskStatus: Equatable {
    case uncompleted
    case completed
}

struct TaskDate {
    
    let date: Date
    let granulity: DateGranulity
    
    init(date: Date, granulity: DateGranulity) {
        self.date = date
        self.granulity = granulity
    }
    
}

class SubTask {
    
}

class RootTask {
    
}

class Task: Equatable, CustomStringConvertible {
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.string == rhs.string
    }
    
    let indent: Int
    let string: String
    let body: String
    var tasks: [Task] = []
    
    let hashtag: String?
    let priority: TaskStatus
    
    let dueDate: TaskDate?
    let startDate: TaskDate?
    
    var isCompleted: Bool {
        return priority == .completed
    }
    
    init(string: String, body: String, priority: TaskStatus = .uncompleted, hashtag: String? = nil, dueDate: TaskDate? = nil, startDate: TaskDate? = nil, indent: Int) {
        self.string = string
        self.body = body
        self.priority = priority
        self.hashtag = hashtag
        self.dueDate = dueDate
        self.startDate = startDate
        self.indent = indent
    }
    
    var description: String {
        var desc = "\(string)\n"
        if tasks.isEmpty {
            desc = "\(string)\n"
        } else {
            desc = "root: \(string)\n"
        }
        
        for task in tasks {
            desc.append(task.description)
        }
        return desc
    }
    
}

