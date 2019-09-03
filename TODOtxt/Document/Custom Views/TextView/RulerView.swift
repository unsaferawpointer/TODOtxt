//
//  RulerView.swift
//  TODO txt
//
//  Created by subzero on 30/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//


import AppKit
import Foundation


enum MarkStyle: Int, CaseIterable {
    case none = 0, bullet, asterisk, cicle, checkbox, point
    var string: String {
        switch self {
        case .none:
            return ""
        case .bullet:
            return "-"
        case .asterisk:
            return "*"
        case .cicle:
            return "◯"
        case .checkbox:
            return "☐"
        case .point:
            return "•"
        }
    }
    var title: String {
        switch self {
        case .none:
            return "None"
        case .bullet:
            return "Bullet"
        case .asterisk:
            return "Asterisk"
        case .cicle:
            return "Cicle"
        case .checkbox:
            return "Checkbox"
        case .point:
            return "Point"
        }
    }
}

extension TextView {
    
    func setUpLineNumberView() {
        
        if let scrollView = enclosingScrollView {
            let rulerView = RulerView(textView: self)
            scrollView.verticalRulerView = rulerView
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
        }
        
    }
    
}

class RulerView: NSRulerView {
    
    var backgroundColor: NSColor {
        return Preferences.shared.theme.background
    }
    
    var foregroundColor: NSColor {
        return Preferences.shared.theme.foreground
    }
    
    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerView.Orientation.verticalRuler)
        self.clientView = textView
        
        self.ruleThickness = 40
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Invalidates view to redraw line numbers
    func invalidateMarks() {
        self.needsDisplay = true
    }
    
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        
        backgroundColor.setFill()
        rect.fill()
        
        let parser = Parser()
        
        if let textView = self.clientView as? NSTextView {
            if let layoutManager = textView.layoutManager {
                
                let baselineOffset = layoutManager.defaultLineHeight(for: textView.font!)
                
                let relativePoint = self.convert(NSZeroPoint, from: textView)
                let markAttributes = [NSAttributedString.Key.font: textView.font!, NSAttributedString.Key.foregroundColor: foregroundColor] as [NSAttributedString.Key : Any]
                
                let drawLineNumber = { (lineNumberString: String, lineRect: NSRect) -> Void in
                    let attString = NSAttributedString(string: lineNumberString, attributes: markAttributes)
                    let x = 35 - attString.size().width
                    // WARNING USING CONSTANT = 8.0 LINE OFFSET
                    let y = lineRect.minY + relativePoint.y + baselineOffset - lineRect.height
                    let origin = NSPoint(x: x, y: y)
                    attString.draw(at: origin)
                }
                
                let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
                
                var glyphIndexForStringLine = visibleGlyphRange.location
                
                // Go through each line in the string.
                while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
                    
                    // Range of current line in the string.
                    let characterRangeForStringLine = (textView.string as NSString).lineRange(
                        for: NSMakeRange( layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0 )
                    )
                    
                    let lineString = textView.string.substring(from: characterRangeForStringLine)
                    var toDraw = true
                    if !parser.hasTodo(lineString) || parser.parse(.status, inLine: lineString) != nil {
                        toDraw = false
                    }
                    
                    let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
                    
                    var glyphIndexForGlyphLine = glyphIndexForStringLine
                    var glyphLineCount = 0
                    
                    while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
                        
                        // See if the current line in the string spread across
                        // several lines of glyphs
                        var effectiveRange = NSMakeRange(0, 0)
                        
                        // Range of current "line of glyphs". If a line is wrapped,
                        // then it will have more than one "line of glyphs"
                        let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                        
                        if glyphLineCount > 0 {
                            if toDraw {
                                drawLineNumber("", lineRect)
                            }
                            
                        } else {
                            if toDraw {
                                drawLineNumber("*", lineRect)
                            }
                            
                        }
                        
                        // Move to next glyph line
                        glyphLineCount += 1
                        glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
                    }
                    
                    glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
                    
                }
                
                /*
                // Draw line number for the extra line at the end of the text
                if layoutManager.extraLineFragmentTextContainer != nil {
                    drawLineNumber("\(lineNumber)", layoutManager.extraLineFragmentRect.minY)
                }*/
            }
        }
    }
}
