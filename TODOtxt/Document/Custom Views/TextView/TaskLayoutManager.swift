//
//  LayoutManager.swift
//  TODOtxt
//
//  Created by subzero on 26/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TaskLayoutManager: NSLayoutManager {
    
    override init() {
        super.init()
        //self.typesetter = NSTypesetter()
        self.glyphGenerator = NSGlyphGenerator()
        self.backgroundLayoutEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //self.typesetter = NSTypesetter()
        self.glyphGenerator = NSGlyphGenerator()
        self.backgroundLayoutEnabled = false
    }
    
    var selectionColor: NSColor {
        return Preferences.shared.theme.selection
    }
    
    override func notShownAttribute(forGlyphAt glyphIndex: Int) -> Bool {
        print(#function)
        if glyphIndex == 2 {
            return true
        }
        return super.notShownAttribute(forGlyphAt: glyphIndex)
    }
    
    override func propertyForGlyph(at glyphIndex: Int) -> NSLayoutManager.GlyphProperty {
        print(#function)
        if glyphIndex == 2 {
            return .null
        }
        return super.propertyForGlyph(at: glyphIndex)
    }
    
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        /*
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage?.enumerateAttribute(NSAttributedString.Key("isHeader"), in: characterRange, options:[], using: { (value, range, stop) in
            if let pinned = value as? Int, pinned == 1 {
                let chRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                let lineUsedRect = lineFragmentUsedRect(forGlyphAt: chRange.location, effectiveRange: nil)//lineFragmentRect(forGlyphAt: chRange.location, effectiveRange: nil)
                let lineRect = lineFragmentRect(forGlyphAt: chRange.location, effectiveRange: nil)
                let totalRect = NSRect(x: Int(lineRect.minX), y: Int(lineUsedRect.minY)-3, width: Int(lineRect.width), height: Int(lineUsedRect.height)+6)
                
                let path = NSBezierPath(roundedRect: totalRect, xRadius: 2.0, yRadius: 2.0)
                
                NSColor.systemOrange.setFill()
                
                //NSColor.separatorColor.setFill()
                path.fill()
                
            } else if let pinned = value as? Int, pinned == 2 {
                
                
                let chRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                let lineUsedRect = lineFragmentUsedRect(forGlyphAt: chRange.location, effectiveRange: nil)//lineFragmentRect(forGlyphAt: chRange.location, effectiveRange: nil)
                let lineRect = lineFragmentRect(forGlyphAt: chRange.location, effectiveRange: nil)
                let totalRect = NSRect(x: Int(lineRect.minX), y: Int(lineUsedRect.minY)-3, width: 14, height: Int(lineUsedRect.height)+6)
                
                let path = NSBezierPath(roundedRect: totalRect, xRadius: 2.0, yRadius: 2.0)
                
                NSColor.systemOrange.setFill()
                
                //NSColor.separatorColor.setFill()
                path.fill()
            }
        })*/
        
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
    }
    
}
