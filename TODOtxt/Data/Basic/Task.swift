//
//  ToDo.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

class Task: NSObject {
    
    override func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? Task {
            return self.string == obj.string
        }
        return false
    }
    
    let string: String
    
    @objc let project: String?
    @objc let context: String?
    @objc let priority: String?
    @objc let dateString: String?
    @objc let status: String?
    
    @objc let dueDate: NSDate?
    
    init(string: String, status: String? = nil, project: String? = nil, context: String? = nil, priority: String? = nil, dateString: String? = nil, dueDate: NSDate? = nil) {
        self.string = string
        self.status = status
        self.project = project
        self.context = context
        self.priority = priority
        self.dateString = dateString
        self.dueDate = dueDate
    }
    
    func key(by element: Element) -> String? {
        switch element {
        case .project:
            return project
        case .context:
            return context
        case .priority:
            return priority
        case .status:
            return status
        case .date(granulity: .day):
            return dateString
        default:
            return nil
        }
    }
    
}

