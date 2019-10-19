//
//  ToDo.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation
import CoreData



enum TaskPriority: Equatable {
    
    case uncompleted
    case completed
    case hasPriority(value: String)
    
}


struct TaskDate {
    
    let date: Date
    let granulity: DateGranulity
    
    init(date: Date, granulity: DateGranulity) {
        self.date = date
        self.granulity = granulity
    }
    
}


class Task: Equatable {
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.string == rhs.string
    }
    
    
    let string: String
    let body: String
    let tasks: [Task] = []
    
    let hashtag: String?
    let priority: TaskPriority
    
    let dueDate: TaskDate?
    let startDate: TaskDate?
    
    var isCompleted: Bool {
        return priority == .completed
    }
    
    init(string: String, body: String, priority: TaskPriority = .uncompleted, hashtag: String? = nil, dueDate: TaskDate? = nil, startDate: TaskDate? = nil) {
        self.string = string
        self.body = body
        self.priority = priority
        self.hashtag = hashtag
        self.dueDate = dueDate
        self.startDate = startDate
    }
    
}

