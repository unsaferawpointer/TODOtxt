//
//  ToDo.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation
import CoreData

@objc enum StatusType2: Int, Comparable, RawRepresentable {
    
    init?(rawValue: Int) {
        self = .completed
    }
    
    typealias RawValue = Int
    var rawValue: Int {
        return 0
    }
    
    static func < (lhs: StatusType2, rhs: StatusType2) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case uncompleted, completed, canceled
}

@objc enum StatusType: Int, Comparable, RawRepresentable {
    
    static func < (lhs: StatusType, rhs: StatusType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    case uncompleted, completed, canceled
}

class Task: NSObject {
    
    override func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? Task {
            return self.string == obj.string
        }
        return false
    }
    
    let string: String
    let body: String
    let tasks: [Task] = []
    
    override var description: String {
        return "Task:\(string)"
    }
    
    override var debugDescription: String {
        return "Task:\(string)"
    }
    
    @objc let hashtag: String?
    @objc let priority: String?
    @objc let status: StatusType
    
    @objc let dueDate: NSDate?
    @objc let startDate: NSDate?
    
    var isCompleted: Bool {
        return status == .completed
    }
    
    init(string: String, body: String, status: StatusType = .uncompleted, hashtag: String? = nil, priority: String? = nil, dueDate: NSDate? = nil, startDate: NSDate? = nil) {
        self.string = string
        self.body = body
        self.status = status
        self.hashtag = hashtag
        self.priority = priority
        self.dueDate = dueDate
        self.startDate = startDate
    }
    
    func key(by element: Element) -> String? {
        switch element {
        case .tag:
            return hashtag
        case .priority:
            return priority
        default:
            fatalError("Don`t implemented")
        }
    }
    
}

