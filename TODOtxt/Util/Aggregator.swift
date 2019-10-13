//
//  Aggregator.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation


/// The class determinate how to group todos by keys
class Aggregator {
    
    typealias Grouping = ((_ todo: Task) -> String?)
    
    private let grouping: Grouping
    
    init(grouping: @escaping Grouping) {
        self.grouping = grouping
    }
    
  
    
    func groupKey(for todo: Task) -> String? {
        return grouping(todo)
    }
    
    func title(for key: String) -> String? {
        return key
    }
    
}

class StatusAggregator: Aggregator {
    init() {
        let grouping = { (_ todo: Task) -> String? in 
            return todo.key(by: .status) == nil ? "uncompleted" : "completed"
        }
        
        super.init(grouping: grouping)
    }
}

/// Class group determinate key by Element
class ElementAggregator: Aggregator {
    
    init(element: Element) {
        
        let grouping = { (_ todo: Task) -> String? in 
            return todo.key(by: element)
        }
        
        super.init(grouping: grouping)
    }
    
}

class DateAggregator: Aggregator {
    
    enum Style: String {
        case overdue
        case today
        case tomorrow
        case current_week
        case current_month
        case current_year
    }
    
    init(style: Style) {
        
        let grouping = { (_ todo: Task) -> String? in
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            guard let date = todo.dueDate as Date? else { return nil }
            //let date = formatter.date(from: str)!
            
            let calendar = NSCalendar.current
            let today = Date()
            
            switch style {
            case .overdue:
                if calendar.compare(today, to: date, toGranularity: .day) == .orderedDescending {
                    return "overdue"
                }
            case .today:
                if calendar.compare(today, to: date, toGranularity: .day) == .orderedSame {
                    return "today"
                }
            case .tomorrow:
                let tomorrow = NSCalendar.current.date(byAdding: .day, value: 1, to: today)!
                    
                if calendar.compare(tomorrow, to: date, toGranularity: .day) == .orderedSame {
                    return "tomorrow"
                }
            case .current_week:
                if calendar.compare(today, to: date, toGranularity: .weekOfYear) == .orderedSame {
                    return "current_week"
                }
            case .current_month:
                if calendar.compare(today, to: date, toGranularity: .month) == .orderedSame {
                    return "current_month"
                }
            case .current_year:
                if calendar.compare(today, to: date, toGranularity: .year) == .orderedSame {
                    return "current_year"
                }
            }
            
            return nil
        }
        
        super.init(grouping: grouping)
    }
    
    
    
}

