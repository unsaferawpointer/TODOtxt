//
//  LayoutManager.swift
//  TODOtxt
//
//  Created by subzero on 26/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TaskLayoutManager: NSLayoutManager {
    

    
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
    
        for index in glyphsToShow.location..<(glyphsToShow.location + glyphsToShow.length)  {
            let characterIndex = characterIndexForGlyph(at: index)
            //let char = textStorage?.mutableString.substring(with: NSRange(location: characterIndex, length: 1))
            let char = textStorage?.mutableString.character(at: characterIndex)
            if char == 0x0009 {
                replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "ntilde"))!)
            }
        }
        
        
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    
  
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
    }
    
}
