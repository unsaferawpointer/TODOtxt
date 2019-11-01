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
    case subTask
    case completed
    case root
}

extension NSAttributedString.Key {
    static let prefix = NSAttributedString.Key("prefix")
}

class TaskLayoutManager: NSLayoutManager {
    
    
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        //print("glyphsToShow = \(glyphsToShow)")
        //print("draw text = \(textStorage?.mutableString.substring(with: glyphsToShow))")
        
        for index in glyphsToShow.location..<(glyphsToShow.location + glyphsToShow.length)  {
            let characterIndex = characterIndexForGlyph(at: index)
            //let char = textStorage?.mutableString.substring(with: NSRange(location: characterIndex, length: 1))
            let char = textStorage?.mutableString.character(at: characterIndex)
            
            if let value = textStorage!.attribute(.prefix, at: characterIndex, effectiveRange: nil) as? Prefix{
                
                var glyph: NSGlyph?
                switch value {
                case .task:
                    glyph = NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "asterisk")
                case .completed:
                    glyph = NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "uni2713")
                case .root:
                    glyph = NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "greater")
                case .subTask:
                    glyph = NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "uni00AD")
                }
                if let g = glyph {
                    replaceGlyph(at: index, withGlyph: g)
                }
            }
            
            
            if char == 0x0009 {
                replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "colon"))!)
            } 
            /*
            if char == 0x000A {
                replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "uni21B2"))!)
            }*/
 
 /*
            else if char == 0x002D {
                replaceGlyph(at: index, withGlyph: (NSFont(name: "IBM Plex Mono", size: 15.0)?.glyph(withName: "uni2713"))!)
            }*/
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    
  
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }
    
}
