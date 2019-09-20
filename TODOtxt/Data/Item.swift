//
//  Item.swift
//  TODOtxt
//
//  Created by subzero on 08/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

@objc(Item)
class Item: NSObject {
    
    var hasBadge: Bool = false
    
    @objc var name: String
    @objc var filter: NSPredicate
    
    convenience init(_ name: String, predicateFormat format: String, argumentArray array: [Any]?) {
        let predicate = NSPredicate(format: format, argumentArray: array)
        //predicate.predicateFormat
        self.init(name, filter: predicate)
    }
    
    convenience override init() {
        self.init("New filter", predicateFormat: "ALL context", argumentArray: nil)
    }
    
    init(_ name: String, filter: NSPredicate) {
        self.name = name
        self.filter = filter
    }
    
}
