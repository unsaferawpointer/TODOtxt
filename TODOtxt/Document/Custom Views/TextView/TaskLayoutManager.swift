//
//  LayoutManager.swift
//  TODOtxt
//
//  Created by subzero on 26/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

extension NSAttributedString.Key {
    static let prefix = NSAttributedString.Key("prefix")
    static let isCollapsed = NSAttributedString.Key("isCollapsed")
}

class TaskLayoutManager: NSLayoutManager {
    
    /*
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
    
        for index in glyphsToShow.location..<(glyphsToShow.location + glyphsToShow.length)  {
            let characterIndex = characterIndexForGlyph(at: index)
            //let char = textStorage?.mutableString.substring(with: NSRange(location: characterIndex, length: 1))
            let char = textStorage?.mutableString.character(at: characterIndex)
            
            if let value = textStorage!.attribute(.prefix, at: characterIndex, effectiveRange: nil) as? Int{
                if value == 1 {
                    replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "greater"))!)
                } else if value == 3 {
                    replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "uni2713"))!)
                }
                
            }
            
            
            if char == 0x0009 {
                replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "brokenbar"))!)
            } /*
            else if char == 0x002D {
                replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "uni2713"))!)
            }*/
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    */
  
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
    }
    
}
