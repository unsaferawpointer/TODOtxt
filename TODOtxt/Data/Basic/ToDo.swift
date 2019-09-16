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
    
    let string: String
    
    let project: String?
    let context: String?
    let priority: String?
    let dateString: String?
    
    init(string: String, project: String? = nil, context: String? = nil, priority: String? = nil, dateString: String? = nil) {
        self.string = string
        self.project = project
        self.context = context
        self.priority = priority
        self.dateString = dateString
    }
    
}

