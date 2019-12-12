//
//  NSRange Extension.swift
//  TODOtxt
//
//  Created by subzero on 18.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Foundation

extension NSRange {
    
    func shifted(by shifting: Int) -> NSRange {
        return NSRange(location: self.location + shifting, length: self.length)
    }
    
    func shifted(by range: NSRange) -> NSRange {
        return NSRange(location: self.location + range.location, length: self.length)
    }
}
