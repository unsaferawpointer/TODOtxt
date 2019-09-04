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
        let uncompletedOperator = Filter.FilterOperator.equals(value: nil)
        let uncompletedFilter = Filter(filterOperator: uncompletedOperator, aggregator: uncompletedAggregator)
        let uncomplete = Item("Uncompleted", filter: uncompletedFilter)
        storage.append(uncomplete)
        
        let archiveAggregator = ElementAggregator(element: .status)
        let archiveOperator = Filter.FilterOperator.notEquals(value: nil)
        let archiveFilter = Filter(filterOperator: archiveOperator, aggregator: archiveAggregator)
        let archive = Item("Archive", filter: archiveFilter)
        storage.append(archive)
        
        let customAggregator = ElementAggregator(element: .project)
        let customOperator = Filter.FilterOperator.containedIn(array: ["home","travel"])
        let customFilter = Filter(filterOperator: customOperator, aggregator: customAggregator) && uncompletedFilter
        let custom = Item("Home and Travel project", filter: customFilter)
        storage.append(custom)
        
        let todayAggregator = DateAggregator(style: .common)
        let todayOperator = Filter.FilterOperator.equals(value: "b_today")
        let todayFilter = Filter(filterOperator: todayOperator, aggregator: todayAggregator) && uncompletedFilter
        let today = Item("Today", filter: todayFilter)
        storage.append(today)
        
        
    }
    
    
    
}
