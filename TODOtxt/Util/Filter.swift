//
//  Filter.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

enum Operator {
    
}

struct Filter { 
    
    enum FilterOperator {
        case equals(value: String?)
        case notEquals(value: String?)
        case moreOrEquals(value: String)
        case lessOrEquals(value: String)
        case contains(value: String)
        case containedIn(array: [String])
        
        func condition(with aggregator: Aggregator) -> Condition {
           
            switch self {
            case .equals(let value):
                let condition = {(_ todo: ToDo) -> Bool in
                    let key = aggregator.groupKey(for: todo)
                    return key == value
                }
                return condition
            case .notEquals(let value):
                let condition = {(_ todo: ToDo) -> Bool in
                    let key = aggregator.groupKey(for: todo)
                    return key != value
                }
                return condition
            case .moreOrEquals(let value):
                let condition = {(_ todo: ToDo) -> Bool in
                    let key = aggregator.groupKey(for: todo)
                    return key ?? "" > value || key == value
                }
                return condition
            case .lessOrEquals(let value):
                let condition = {(_ todo: ToDo) -> Bool in
                    let key = aggregator.groupKey(for: todo)
                    return key ?? "" < value || key == value
                }
                return condition
            case .contains(let value):
                let condition = {(_ todo: ToDo) -> Bool in
                    let key = aggregator.groupKey(for: todo)
                    return (key ?? "").contains(value)
                }
                return condition
            case .containedIn(let array):
                let condition = {(_ todo: ToDo) -> Bool in
                    let key = aggregator.groupKey(for: todo) ?? ""
                    return array.contains(key)
                }
                return condition
            }
        }
    }
    
    
    
    typealias Condition = ((_ todo: ToDo) -> Bool)
    
    var name: String 
    private var condition: Condition
    
    init(_ name: String = "", filterOperator: FilterOperator, aggregator: Aggregator) {
        self.name = name
        self.condition = filterOperator.condition(with: aggregator)
    }
    
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
    
    /// Body contains value
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




