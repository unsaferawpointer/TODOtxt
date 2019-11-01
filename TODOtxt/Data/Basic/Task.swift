//
//  ToDo.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa



protocol LineObject {
    var string: String { get }
    var body: String { get }
}

class Event: LineObject {
    
    var body: String {
        return string
    }
    
    
    let string: String
    let hashtag: String?
    let isCancelled: Bool
    
    let date: ObjectDate?
    
    init(_ string: String, isCancelled: Bool, at date: ObjectDate?, hashtag: String?) {
        self.string = string
        self.isCancelled = isCancelled
        self.date = date
        self.hashtag = hashtag
    }
    
}

class Task: LineObject, Equatable, CustomStringConvertible {
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.string == rhs.string
    }
    
    let indent: Int
    
    let string: String
    let body: String
    let tasks: [Task] = []
    
    let hashtag: String?
    
    let dueDate: ObjectDate?
    let startDate: ObjectDate?
    
    let isCompleted: Bool
    
    init(string: String, body: String, isCompleted: Bool, hashtag: String? = nil, dueDate: ObjectDate? = nil, startDate: ObjectDate? = nil, indent: Int) {
        self.string = string
        self.body = body
        self.isCompleted = isCompleted
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

