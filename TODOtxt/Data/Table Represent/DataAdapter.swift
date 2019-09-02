//
//  DataAdapter.swift
//  TODO txt
//
//  Created by subzero on 26/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

class Item: NSObject {
    
    var hasBadge: Bool = false
    
    dynamic var name: String
    var filter: Filter
    
    init(_ name: String, filter: Filter) {
        self.name = name
        self.filter = filter
    }
    
}

class DataAdapter {
    
    var storage: [Item]
    
    init() {
        self.storage = []
        configure()
    }
    
    private func configure() {
        
        let allFilter = Filter(alwaysReturn: true)
        let all = Item("All", filter: allFilter)
        storage.append(all)
        
        let uncompletedFilter = Filter(element: .status, equals: nil)
        let uncomplete = Item("Uncompleted", filter: uncompletedFilter)
        storage.append(uncomplete)
        
        let archiveFilter = Filter(element: .status, notEquals: nil)
        let archive = Item("Archive", filter: archiveFilter)
        storage.append(archive)
        
        let hasContextFilter = Filter(element: .context, notEquals: nil) && uncompletedFilter
        let hasContext = Item("Has context", filter: hasContextFilter)
        storage.append(hasContext)
        
        let todayFilter = DateAggregator(style: .common).filter(groupKeyEquals: "b_today") && uncompletedFilter
        let today = Item("Today", filter: todayFilter)
        today.hasBadge = true
        storage.append(today)
        
        let hasDateFilter = Filter(element: .date(granulity: .day), notEquals: nil) && uncompletedFilter
        let hasDate = Item("Has date", filter: hasDateFilter)
        storage.append(hasDate)
        
        let overdueFilter = DateAggregator(style: .common).filter(groupKeyEquals: "a_overdue") && uncompletedFilter
        let overdue = Item("Overdue", filter: overdueFilter)
        storage.append(overdue)
        
        let containsFilter = Filter(contains: "important") && uncompletedFilter
        let contains = Item("Important", filter: containsFilter)
        storage.append(contains)
    }
    
    
    
}
