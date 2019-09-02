//
//  Filter.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

struct Filter { 
    
    typealias Condition = ((_ todo: ToDo) -> Bool)
    
    var name: String 
    private var condition: Condition
    
    init(_ name: String = "", alwaysReturn result: Bool) {
        self.name = name
        self.condition = { (_ todo: ToDo) -> Bool in
            return result
        }
    }
    
    init(_ name: String = "", condition: @escaping ((_ todo: ToDo) -> Bool)) {
        self.name = name
        self.condition = condition
    }
    
    
    init(_ name: String = "", element: Element, notEquals  value: String?) {
        self.name = name
        let condition = {(_ todo: ToDo) -> Bool in
            return todo.key(by: element) != value
        }
        self.condition = condition
    }
    
    init(_ name: String = "", element: Element, equals  value: String?) {
        self.name = name
        let condition = {(_ todo: ToDo) -> Bool in
            return todo.key(by: element) == value
        }
        self.condition = condition
    }
    
    init(_ name: String = "", notNil element: Element) {
        self.name = name
        let condition = {(_ todo: ToDo) -> Bool in
            return todo.key(by: element) != nil
        }
        self.condition = condition
    }
    
    init(_ name: String = "", aggregator: Aggregator, equals value: String?) {
        self.name = aggregator.name
        let condition = {(_ todo: ToDo) -> Bool in 
            return aggregator.groupKey(for: todo) == value
        }
        self.condition = condition
    }
    
    init(_ name: String = "", contains value: String) {
        self.name = name
        let condition = {(_ todo: ToDo) -> Bool in 
            return todo.string.contains(value)
        }
        self.condition = condition
    }
    
    func contains(_ todo: ToDo) -> Bool {
        return condition(todo)
    }
    
}

extension Filter {
    
    static func && (lhs: Filter, rhs: Filter) -> Filter {
        let name = "\(lhs.name) && \(rhs.name)"
        let lhsCondition = lhs.condition
        let rhsCondition = rhs.condition
        let condition = { [lhsCondition, rhsCondition] (_ todo: ToDo) -> Bool in
            return lhsCondition(todo) && rhsCondition(todo)
        }
        let filter = Filter(name, condition: condition)
        return filter
    }
    
    static func || (lhs: Filter, rhs: Filter) -> Filter {
        let name = "\(lhs.name) || \(rhs.name)"
        let lhsCondition = lhs.condition
        let rhsCondition = rhs.condition
        let condition = { [lhsCondition, rhsCondition](_ todo: ToDo) -> Bool in
            return lhsCondition(todo) || rhsCondition(todo)
        }
        let filter = Filter(name, condition: condition)
        return filter
    }
    
}




