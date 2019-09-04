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
        
        let uncompletedAggregator = ElementAggregator(element: .status)
        let uncompletedFilter = Filter(filterOperator: .equals, value: nil, aggregator: uncompletedAggregator)
        let uncomplete = Item("Uncompleted", filter: uncompletedFilter)
        storage.append(uncomplete)
        
        let archiveAggregator = ElementAggregator(element: .status)
        let archiveFilter = Filter(filterOperator: .notEquals, value: nil,  aggregator: archiveAggregator)
        let archive = Item("Archive", filter: archiveFilter)
        storage.append(archive)
        
        let todayAggregator = DateAggregator(style: .common)
        let todayFilter = Filter(filterOperator: .equals, value: "b_today", aggregator: todayAggregator) && uncompletedFilter
        let today = Item("Today", filter: todayFilter)
        storage.append(today)
        
        
    }
    
    
    
}
