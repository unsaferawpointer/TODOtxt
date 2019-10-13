//
//  LineFoldingGlyphGenerator.swift
//  TODOtxt
//
//  Created by subzero on 09.10.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

import Cocoa

class LineFoldingGlyphGenerator: NSGlyphGenerator, NSGlyphStorage {
    
    var destination: NSGlyphStorage
    
    init(glyphStorage: NSGlyphStorage) {
        destination = glyphStorage
    }
    
    override func generateGlyphs(for glyphStorage: NSGlyphStorage, desiredNumberOfCharacters nChars: Int, glyphIndex: UnsafeMutablePointer<Int>?, characterIndex charIndex: UnsafeMutablePointer<Int>?) {
        
        let instance = NSGlyphGenerator.shared
        
        destination = glyphStorage
        instance.generateGlyphs(for: self, desiredNumberOfCharacters: nChars, glyphIndex: glyphIndex, characterIndex: charIndex)
        //destination = nil
    }
    
    func attributedString() -> NSAttributedString {
        return destination.attributedString()
    }
    
    func layoutOptions() -> Int {
        return destination.layoutOptions()
    }
    
    func insertGlyphs(_ glyphs: UnsafePointer<NSGlyph>, length: Int, forStartingGlyphAt glyphIndex: Int, characterIndex charIndex: Int) {
        
        var myGlyphs = [NSGlyph]()
        
        let effectiveRange = UnsafeMutablePointer<NSRange>.allocate(capacity: 1)
        let foldingAttr = NSAttributedString.Key("folding")
        let range = NSRange(location: 0, length: charIndex + length)
        print(#function)
        if let attribute = self.attributedString().attribute(foldingAttr, at: charIndex, longestEffectiveRange: effectiveRange, in: range) as? Bool, attribute == true {
            myGlyphs = Array.init(repeating: NSGlyph(NSNullGlyph), count: length)
            if effectiveRange.pointee.location == charIndex {
                myGlyphs[0] = NSGlyph(NSControlGlyph)
            }
        }
        
        destination.insertGlyphs(myGlyphs, length: length, forStartingGlyphAt: glyphIndex, characterIndex: charIndex)
        
    }
    
    func setIntAttribute(_ attributeTag: Int, value val: Int, forGlyphAt glyphIndex: Int) {
        destination.setIntAttribute(attributeTag, value: val, forGlyphAt: glyphIndex)
    }
    
}
