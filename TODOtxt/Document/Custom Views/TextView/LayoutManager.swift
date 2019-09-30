//
//  LayoutManager.swift
//  TODOtxt
//
//  Created by subzero on 26/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class LayoutManager: NSLayoutManager {
    
    var selectionColor: NSColor {
        return Preferences.shared.theme.selection
    }
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        var totalRect: NSRect?
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage?.enumerateAttribute(NSAttributedString.Key("pinned"), in: characterRange, options:[], using: { (value, range, stop) in
            if let pinned = value as? Int, pinned == 1 {
                let chRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                let lineRect = lineFragmentRect(forGlyphAt: chRange.location, effectiveRange: nil)
                
                if totalRect != nil {
                    totalRect = totalRect!.union(lineRect)
                } else {
                    totalRect = lineRect
                }
                
            }
        })
        
        
        if let rect = totalRect {
            let path = NSBezierPath(roundedRect: rect, xRadius: 4.0, yRadius: 4.0)
            selectionColor.setFill()
            path.fill()
        }
        
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
    }
    
}
