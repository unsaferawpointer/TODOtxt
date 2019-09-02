//
//  String Extention.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

extension String {
    
    func substring(from range: NSRange) -> String {
        if let stringRange = Range(range, in: self) {
            return String(self[stringRange])
        }
        return ""
    }
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: count)
    }
    
}

