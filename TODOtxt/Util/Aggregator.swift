//
//  Aggregator.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

enum PriorityStyle: Int, CaseIterable {
    case common = 0, importance
    
    var title: String {
        switch self {
        case .common:
            return "default"
        case .importance:
            return "importance"
        }
    }
}


/// The class determinate how to group todos by keys
class Aggregator {
    
    typealias Grouping = ((_ todo: ToDo) -> String?)
    
    let name: String
    private let grouping: Grouping
    
    init(_ name: String = "", grouping: @escaping Grouping) {
        self.name = name
        self.grouping = grouping
    }
    
    /// Return filter where todo has groupKey != nil
    var filter: Filter {
        let condition = { (_ todo: ToDo) -> Bool in
            return self.grouping(todo) != nil
        }
        let filter = Filter(name, condition: condition)
        return filter
    }
    
    func filter(groupKeyEquals value: String) -> Filter {
        let condition = { [self] (_ todo: ToDo) -> Bool in
            return self.grouping(todo) == value
        }
        let filter = Filter("\(name) = \(value)", condition: condition)
        return filter
    }
    
    func groupKey(for todo: ToDo) -> String? {
        return grouping(todo)
    }
    
    func title(for key: String) -> String? {
        return key
    }
    
}

/// Class group determinate key by Element
class ElementAggregator: Aggregator {
    
    init(_ name: String = "", element: Element) {
        
        let grouping = { (_ todo: ToDo) -> String? in 
            return todo.key(by: element)
        }
        
        super.init(name , grouping: grouping)
    }
    
}

class DateAggregator: Aggregator {
    
    let style: DateStyle
    
    init(_ name: String = "", style: DateStyle = .common) {
        self.style = style
        let grouping = { (_ todo: ToDo) -> String? in
            switch style {
            case .common:
                let today = Date()
                let tomorrow = NSCalendar.current.date(byAdding: .day, value: 1, to: today)!
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let stringDate = todo.dictionary[.date(granulity: .day)]
                guard stringDate != nil else { return nil}
                
                let date = dateFormatter.date(from: stringDate!)
                precondition(date != nil, "Date from string is nil. Check validation of the date")
                
                
                if NSCalendar.current.compare(today, to: date!, toGranularity: .day) == .orderedDescending {
                    return "a_overdue"
                } else if NSCalendar.current.compare(today, to: date!, toGranularity: .day) == .orderedSame {
                    return "b_today"
                } else if NSCalendar.current.compare(tomorrow, to: date!, toGranularity: .day) == .orderedSame {
                    return "c_tomorrow"
                }else if NSCalendar.current.compare(today, to: date!, toGranularity: .weekOfYear) == .orderedSame {
                    return "d_week"
                } else if NSCalendar.current.compare(today, to: date!, toGranularity: .month) == .orderedSame {
                    return "e_month"
                } else {
                    return "f_later"
                }
            case .day:
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let stringDate = todo.dictionary[.date(granulity: .day)]
                guard stringDate != nil else { return nil}
                
                return stringDate!
            case .month:
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let stringDate = todo.dictionary[.date(granulity: .day)]
                guard stringDate != nil else { return nil}
                
                let date = dateFormatter.date(from: stringDate!)
                precondition(date != nil, "Date from string is nil. Check validation of the date")
                
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "yyyy-MM"
                return monthFormatter.string(from: date!)
            case .year:
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let stringDate = todo.dictionary[.date(granulity: .day)]
                guard stringDate != nil else { return nil}
                
                let date = dateFormatter.date(from: stringDate!)
                precondition(date != nil, "Date from string is nil. Check validation of the date")
                
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "yyyy"
                return monthFormatter.string(from: date!)
            }
        }
        
        super.init(name, grouping: grouping)
    }
    
    override func title(for key: String) -> String {
        switch style {
        case .day:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.date(from: key)
            
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "E, yyyy-MM-dd"
            
            return monthFormatter.string(from: date!)
        case .month:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            let date = dateFormatter.date(from: key)
            
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM yyyy"
            
            return monthFormatter.string(from: date!)
        case .common:
            switch key {
            case "a_overdue":
                return "Overdue"
            case "b_today":
                return "Today"
            case "c_tomorrow":
                return "Tomorrow"
            case "d_week":
                return "This week"
            case "e_month":
                return "This Month"
            case "f_later":
                return "Later"
            default:
                return "Indefenied"
            }
        default:
            return key
        }
    }
    
}

