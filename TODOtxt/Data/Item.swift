//
//  Item.swift
//  TODOtxt
//
//  Created by subzero on 08/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

class Item: NSObject {
    
    var hasBadge: Bool = false
    
    @objc var name: String
    var filter: NSPredicate
    
    init(_ name: String, filter: NSPredicate) {
        self.name = name
        self.filter = filter
    }
    
}
