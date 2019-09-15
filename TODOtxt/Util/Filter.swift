//
//  Filter.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

struct WrappedCondition {
    
    let value: (_ todo: ToDo) -> Bool
    
    init(_ value: Condition) {
        self.value = value.condition
    }
    
    init(_ value: @escaping (_ todo: ToDo) -> Bool) {
        self.value = value
    }
    
    static func && (left: WrappedCondition, right: WrappedCondition) -> WrappedCondition {
        let newCondition = { (_ todo: ToDo) -> Bool in 
            return left.value(todo) && right.value(todo)
        }
        return WrappedCondition(newCondition)
    }
    
    static func || (left: WrappedCondition, right: WrappedCondition) -> WrappedCondition {
        let newCondition = { (_ todo: ToDo) -> Bool in 
            return left.value(todo) || right.value(todo)
        }
        return WrappedCondition(newCondition)
    }
    
}

enum FilterExpression {
    
    case condition(WrappedCondition)
    indirect case addition(FilterExpression, FilterExpression)
    indirect case multiplication(FilterExpression, FilterExpression)
    
    private func evaluate(_ expression: FilterExpression) -> WrappedCondition {
        switch expression {
        case let .condition(value):
            return value
        case let .addition(left, right):
            return evaluate(left) || evaluate(right)
        case let .multiplication(left, right):
            return evaluate(left) && evaluate(right)
        }
    }
    
    func evaluate() -> WrappedCondition {
        return evaluate(self)
    }
    
    func contains(_ todo: ToDo) -> Bool {
        let condition = evaluate()
        return condition.value(todo)
    }
}

// ******** Parsing ********

enum FilterOperator {
    
    case equals, notEquals, more, less, moreOrEquals, lessOrEquals, contains
    
    init? (_ rawValue: String) {
        switch rawValue {
        case "=":
            self = .equals
        case "!=":
            self = .notEquals
        case ">":
            self = .more
        case "<":
            self = .less
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
    
    func compare(lhs: String, rhs: String) -> Bool {
        switch self {
        case .equals:
            return lhs == rhs
        case .notEquals:
            return lhs != rhs
        case .more:
            return lhs > rhs
        case .less:
            return lhs < rhs
        case .moreOrEquals:
            return lhs > rhs || lhs == rhs
        case .lessOrEquals:
            return lhs < rhs || lhs == rhs
        case .contains:
            return lhs.contains(rhs)
        }
    }
}

protocol Condition {
    var condition: (_ todo: ToDo) -> Bool { get }
}

enum DateCondition: Condition {
    
    case today, tomorrow, overdue, current_week, current_month, current_year
    
    init? (rawValue: String) {
        switch rawValue {
        case "today":
            self = .today
        case "tomorrow":
            self = .tomorrow
        case "overdue":
            self = .overdue
        case "current_week":
            self = .current_week
        case "current_month":
            self = .current_month
        case "current_year":
            self = .current_year
        default:
            return nil
        }
    }
    
    var condition: (_ todo: ToDo) -> Bool {
        
        let result = { (_ todo: ToDo) -> Bool in
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            guard let str = todo.dictionary[.date(granulity: .day)] else { return false }
            let date = formatter.date(from: str)!
            
            let calendar = NSCalendar.current
            let today = Date()
            
            switch self {
            case .overdue:
                if calendar.compare(today, to: date, toGranularity: .day) == .orderedDescending {
                    return true
                }
            case .today:
                if calendar.compare(today, to: date, toGranularity: .day) == .orderedSame {
                    return true
                }
            case .tomorrow:
                let tomorrow = NSCalendar.current.date(byAdding: .day, value: 1, to: today)!
                
                if calendar.compare(tomorrow, to: date, toGranularity: .day) == .orderedSame {
                    return true
                }
            case .current_week:
                if calendar.compare(today, to: date, toGranularity: .weekOfYear) == .orderedSame {
                    return true
                }
            case .current_month:
                if calendar.compare(today, to: date, toGranularity: .month) == .orderedSame {
                    return true
                }
            case .current_year:
                if calendar.compare(today, to: date, toGranularity: .year) == .orderedSame {
                    return true
                }
            }
            
            return false
            
        }
        
        return result
    }
    
    
}

enum StatusCondition {
    
    case completed, uncompleted
    
    init? (rawValue: String) {
        switch rawValue {
        case "completed":
            self = .completed
        case "uncompleted":
            self = .uncompleted
        default:
            return nil
        }
    }
    
    var condition: (_ todo: ToDo) -> Bool {
        
        let result = { (_ todo: ToDo) -> Bool in
            
            let status = todo.key(by: .status)
            
            switch self {
            case .completed:
                return  status != nil
            case .uncompleted:
                return status == nil
            }
            
        }
        
        return result
    }
    
    
}

enum ElementCondition {
    
    case project(operation: FilterOperator, value: String)
    case context(operation: FilterOperator, value: String)
    case date(operation: FilterOperator, value: String)
    case priority(operation: FilterOperator, value: String)
    
    init?(mention: Element, operation: FilterOperator, value: String) {
        switch mention {
        case .project:
            self = .project(operation: operation, value: value)
        case .context:
            self = .context(operation: operation, value: value)
        case .date(granulity: .day):
            self = .date(operation: operation, value: value)
        case .priority:
            self = .priority(operation: operation, value: value)
        default:
            return nil
        }
    }
    
    var condition: (_ todo: ToDo) -> Bool {
        let result = { (_ todo: ToDo) -> Bool in
            
            switch self {
            case .project(let operation, let value):
                if let key = todo.key(by: .project) {
                    return operation.compare(lhs: key, rhs: value)
                }
            case .context(let operation, let value):
                if let key = todo.key(by: .context) {
                    return operation.compare(lhs: key, rhs: value)
                }
            case .date(let operation, let value):
                if let key = todo.key(by: .date(granulity: .day)) {
                    return operation.compare(lhs: key, rhs: value)
                }
            case .priority(let operation, let value):
                if let key = todo.key(by: .priority) {
                    return operation.compare(lhs: key, rhs: value)
                }
            }
            
            return false
            
        }
        
        return result
    }
    
}

class FilterParser {
    
    enum FilterError: Error {
        case operatorError
        case mentionError
        case valueError
        case notExist
    }
    
    func parseDateAggregatorCondition(from str: String) throws -> FilterExpression? {
        
        let range = str.fullRange
        let pattern = #"\s*\.(today|tomorrow|overdue|current_week|current_month|current_year)\s*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        if let match = regex.firstMatch(in: str, options: [], range: range) {
            
            let value = str.substring(from: match.range(at: 1))
            if let dateCondition = DateCondition(rawValue: value) {
                let wrappedCondition = WrappedCondition(dateCondition)
                return FilterExpression.condition(wrappedCondition)
            }
        }
        
        return nil
    }
    
}

/*

class FilterParser {
    
    enum FilterError: Error {
        case operatorError
        case mentionError
        case valueError
        case notExist
    }
    
    func parse(form str: String) throws -> FilterExpression {
        
        var result: FilterCondition?
        guard !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Filter(condition: { (todo) -> Bool in
                return true
            })
        }
        
        do {
            if let condition = try parseElementCondition(from: str) {
                result = condition
            } else if let condition = try parseDateElementCondition(from: str) {
                result = condition
            } else if let condition = try parseDateAggregatorCondition(from: str) {
                result = condition
            } else if let condition = try parseStatusCondition(from: str) {
                result = condition
            }
        }
        
        if let condition = result {
            let filter = FilterExpression.value(condition)
            return filter
        } else {
            throw FilterError.notExist
        }
        
        
    }
    
    func parseElementCondition(from str: String) throws -> FilterCondition? {
        let range = str.fullRange
        let pattern = #"^\s*(project|context|priority)\s+(=|=>|<=|contains)\s+(\w+)\s*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        if let match = regex.firstMatch(in: str, options: [], range: range) {
           
            let mentionStr = str.substring(from: match.range(at: 1))
            let filterOperatorStr = str.substring(from: match.range(at: 2))
            let value = str.substring(from: match.range(at: 3))
            
            guard let filterOperator = FilterOperator(filterOperatorStr) else { 
                throw DataError.invalidFormat  
            }
            
            guard let mention = Element(rawValue: mentionStr) else { 
                throw DataError.invalidFormat
            }
            
            let condition = ElementCondition(mention: mention, operation: filterOperator, value: value)
            
            return condition?.condition
        }
        
        return nil
    }
    
    func parseDateElementCondition(from str: String) throws -> FilterCondition? {
        let range = str.fullRange
        let pattern = #"^\s*(date)\s+(=|=>|<=)\s+((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])-([123]0|[012][1-9]|31))\s*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        if let match = regex.firstMatch(in: str, options: [], range: range) {
            
            //let mentionStr = str.substring(from: match.range(at: 1))
            let filterOperatorStr = str.substring(from: match.range(at: 2))
            let value = str.substring(from: match.range(at: 3))
            
            guard let filterOperator = FilterOperator(filterOperatorStr) else { 
                throw DataError.invalidFormat  
            }
            let mention = Element.date(granulity: .day)
            
            if let condition = ElementCondition(mention: mention, operation: filterOperator, value: value) {
                return FilterExpression.value(FilterCondition(condition: condition.condition))
            }
            
            return nil
        }
        
        return nil
    }
    
    func parseDateAggregatorCondition(from str: String) throws -> FilterCondition? {
        let range = str.fullRange
        let pattern = #"\s*\.(today|tomorrow|overdue|current_week|current_month|current_year)\s*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        if let match = regex.firstMatch(in: str, options: [], range: range) {
            
            let value = str.substring(from: match.range(at: 3))
            
            guard let style = DateAggregator.Style(rawValue: value) else { 
                throw DataError.invalidFormat  
            }
            
            let aggregator = DateAggregator.init(style: style)
            
            let condition = {(_ todo: ToDo) -> Bool in
                let key = aggregator.groupKey(for: todo)
                return key == value
            }
                
            return condition
        }
        
        return nil
    }
    
    func parseStatusCondition(from str: String) throws -> FilterCondition? {
        let range = str.fullRange
        let pattern = #"\s*\.(completed|uncompleted)\s*$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        if let match = regex.firstMatch(in: str, options: [], range: range) {
            let value = str.substring(from: match.range(at: 1))
            let aggregator = StatusAggregator()
            let condition = {(_ todo: ToDo) -> Bool in
                let key = aggregator.groupKey(for: todo)
                return key == value
            }
            return condition
        }
        
        return nil
    }
    
          
    
}



*/



