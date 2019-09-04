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

class Filter { 
    
    enum FilterOperator {
        case equals
        case notEquals
        case moreOrEquals
        case lessOrEquals
        case contains
        
        init? (_ rawValue: String) {
            switch rawValue {
            case "=":
                self = .equals
            case "!=":
                self = .notEquals
            case "=>":
                self = .moreOrEquals
            case "<=":
                self = .lessOrEquals
            case "contains":
                self = .contains
            default:
                return nil
            }
        }
    }
    
    
    
    typealias Condition = ((_ todo: ToDo) -> Bool)
    
    var name: String 
    private var condition: Condition = {(todo: ToDo) -> Bool in return true }
    
    init(_ name: String = "") {
        self.name = name
    }
    
    init(_ name: String = "", filterOperator: FilterOperator, value: String?, aggregator: Aggregator) {
        self.name = name
        self.setCondition(filterOperator: filterOperator, value: value, aggregator: aggregator)
    }
    
    func setCondition(filterOperator: FilterOperator, value: String?, aggregator: Aggregator) {
        switch filterOperator {
        case .equals:
            self.condition = {(_ todo: ToDo) -> Bool in
                let key = aggregator.groupKey(for: todo)
                return key == value
            }
        case .notEquals:
            self.condition = {(_ todo: ToDo) -> Bool in
                let key = aggregator.groupKey(for: todo)
                return key != value
            }
        case .moreOrEquals:
            self.condition = {(_ todo: ToDo) -> Bool in
                let key = aggregator.groupKey(for: todo)
                return key ?? "" > value ?? "" || key == value
            }
        case .lessOrEquals:
            self.condition = {(_ todo: ToDo) -> Bool in
                let key = aggregator.groupKey(for: todo)
                return key ?? "" < value ?? "" || key == value
            }
        case .contains:
            self.condition = {(_ todo: ToDo) -> Bool in
                let key = aggregator.groupKey(for: todo)
                return (key ?? "").contains(value ?? "")
            }
        }
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




