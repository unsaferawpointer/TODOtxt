//
//  Comparator.swift
//  TODO txt
//
//  Created by subzero on 01/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation


struct ElementComparator {
    
    var element: Element
    
    init(element: Element) {
        self.element = element
    }
}

struct Comparator {
    var order: [Element] = [.priority, .project, .date(granulity: .day), .context]
    
    func compare(_ lhs: ToDo, _ rhs: ToDo) -> Bool {
        
        // Reverse status comparison
        let lhsStatus = lhs.dictionary[.status]
        let rhsStatus = rhs.dictionary[.status]
        guard lhsStatus == rhsStatus else { 
            return compare(lhs: rhsStatus, rhs: lhsStatus)
        }
        
        for mention in order {
            let lhsValue = lhs.dictionary[mention]
            let rhsValue = rhs.dictionary[mention]
            if lhsValue != rhsValue {
                return compare(lhs: lhsValue, rhs: rhsValue)
            }
            
        }
        
        return compare(lhs: lhs.string, rhs: rhs.string)
    }
    
    private func compare<Element: Comparable>(lhs: Element?, rhs: Element?) -> Bool {
        if lhs == nil {
            return false
        } else if rhs == nil {
            return true
        } else {
            return lhs! < rhs!
        }
    }
    
    /*
    func compare <Element: Comparable> (lhs: Element?, rhs: Element?) -> ComparisonResult {
        if lhs == nil {
            return .orderedDescending
        } else if rhs == nil {
            return .orderedAscending
        } else if lhs! < rhs! {
            return .orderedAscending
        } else if lhs! > rhs! {
            return .orderedDescending
        }
        
        return .orderedSame
    }*/
}


