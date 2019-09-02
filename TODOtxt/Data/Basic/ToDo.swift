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

