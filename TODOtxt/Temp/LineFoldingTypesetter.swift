//
//  LineFoldingTypesetter.swift
//  TODOtxt
//
//  Created by subzero on 10.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class LineFoldingTypesetter: NSTypesetter {
    override func actionForControlCharacter(at charIndex: Int) -> 
        NSTypesetterControlCharacterAction {
        
        let foldingAttr = NSAttributedString.Key("folding")
            
        if let attribute = self.attributedString?.attribute(foldingAttr, at: charIndex, effectiveRange: nil) as? Bool, attribute == true {
            return .zeroAdvancementAction
        }
            
        return super.actionForControlCharacter(at: charIndex)
    }
    
    
}
