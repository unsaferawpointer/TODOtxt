//
//  ToDo.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

func == (lhs: ToDo, rhs: ToDo) -> Bool {
    return lhs.string == rhs.string
}

struct ToDo: Hashable, CustomStringConvertible {
    
    var string: String
    var dictionary: [Element: String] = [:]
    
    var description: String {
        return "TODO: \(string)"
    }
    
    func key(by element: Element) -> String? {
        return dictionary[element]
    }
    
    init(string: String, dictionary: [Element: String] = [:]) {
        self.string = string
        self.dictionary = dictionary
    }
    
}

class Task: NSObject {
    
    override func isEqual(_ object: Any?) -> Bool {
        if let obj = object as? Task {
            return self.string == obj.string
        }
        return false
    }
    
    let string: String
    
    let project: String?
    @objc let context: String?
    let priority: String?
    let dateString: String?
    let status: String?
    
    init(string: String, status: String? = nil, project: String? = nil, context: String? = nil, priority: String? = nil, dateString: String? = nil) {
        self.string = string
        self.status = status
        self.project = project
        self.context = context
        self.priority = priority
        self.dateString = dateString
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

