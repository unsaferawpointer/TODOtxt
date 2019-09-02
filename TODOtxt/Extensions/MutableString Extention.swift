//
//  MutableString Extention.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

extension NSMutableString {
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: length)
    }
    
    var string: String {
        return substring(with: fullRange)
    }
    
    func singleLine(for range: NSRange) -> NSRange? {
        let lines = lineRange(for: range)
        
        var count = 0
        enumerateSubstrings(in: lines, options: .byLines) { (_, _, _, stop) in
            count += 1
            if count > 1 { stop.pointee = ObjCBool(booleanLiteral: true) }
        }
        
        return count == 1 ? lines : nil
    }
    
}
