//
//  LayoutManager.swift
//  TODOtxt
//
//  Created by subzero on 26/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum Prefix {
    case task
    case completed
    case root
}

enum Mark {
    case asterisk
    case bullet
    case dash
}

extension NSAttributedString.Key {
    static let prefix = NSAttributedString.Key("prefix")
    static let isCollapsed = NSAttributedString.Key("isCollapsed")
}

class TaskLayoutManager: NSLayoutManager {
    
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        let font = NSFont(name: "IBM Plex Mono", size: 15.0)!
        
        
        for index in glyphsToShow.location..<(glyphsToShow.location + glyphsToShow.length)  {
            let characterIndex = characterIndexForGlyph(at: index)
            let char = textStorage?.mutableString.character(at: characterIndex)
            
            if let value = textStorage!.attribute(.prefix, at: characterIndex, effectiveRange: nil) as? Prefix {
                
                var glyph: NSGlyph?
                switch value {
                case .task:
                    glyph = font.glyph(withName: "bullet")
                    //glyph = NSFont(name: "Apple Symbols", size: 15.0)?.glyph(withName: "uni2612")//
                case .completed:
                    glyph = font.glyph(withName: "uni2713")
                case .root:
                    glyph = font.glyph(withName: "greater")
                }
                if let g = glyph {
                    replaceGlyph(at: index, withGlyph: g)
                }
            }
            
            // Replace tabulation
            if char == 0x0009 {
                replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "uni2192"))!)
            } 
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }
    
}
