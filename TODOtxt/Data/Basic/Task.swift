//
//  ToDo.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa



class Event: LineObject {
    
    var body: String {
        return string
    }
    
    let string: String
    let hashtag: HashtagToken?
    let isCancelled: Bool
    
    let date: DateToken?
    
    init(_ string: String, isCancelled: Bool, at date: DateToken?, hashtag: HashtagToken?) {
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
    
    let hashtag: HashtagToken?
    
    let dueDate: DateToken?
    let startDate: DateToken?
    
    let isCompleted: Bool
    
    init(string: String, body: String, isCompleted: Bool, hashtag: HashtagToken? = nil, dueDate: DateToken? = nil, startDate: DateToken? = nil, indent: Int) {
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
        return desc
    }
    
}

