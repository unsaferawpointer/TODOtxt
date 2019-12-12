//
//  Highlighter.swift
//  TODOtxt
//
//  Created by subzero on 01.11.2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class Highlighter {
    
    var font: NSFont
    var boldFont: NSFont
    
    let fontName = "IBM Plex Mono"
    let boldFontName = "IBM Plex Mono Medium"
    
    lazy var otherParagraphStyle: NSMutableParagraphStyle = {
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.defaultTabInterval = 24.0
        style.firstLineHeadIndent = 24.0
        style.tabStops = [NSTextTab(textAlignment: .left, location: 24.0, options: [NSTextTab.OptionKey.columnTerminators:NSCharacterSet.whitespacesAndNewlines])]
        return style
    }()
    
    lazy var headerParagraphStyle: NSMutableParagraphStyle = {
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.firstLineHeadIndent = 10.0
        style.paragraphSpacing = 4.0
        style.alignment = .left
        return style
    }()
    
    lazy var taskParagraphStyle: NSMutableParagraphStyle = {
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.lineHeightMultiple = 1.0
        style.lineSpacing = 0.0
        style.paragraphSpacing = 4.0
        style.firstLineHeadIndent = 24.0
        style.defaultTabInterval = 24.0
        style.tabStops = [NSTextTab(type: .leftTabStopType, location: 24.0)]
        return style
    }()
    
    var parser: Parser
    
    // ******** Init block ********
    
    init(parser: Parser = Parser()) {
        self.parser = parser
        self.font = NSFont(name: "IBM Plex Mono", size: 14.0)!
        self.boldFont = NSFont(name: "IBM Plex Mono Medium", size: 14.0)!
    }
    
    // ******** Hightligthing ********
    
    func hightlight(_ backingStorage: NSMutableAttributedString, in editedRange: NSRange) {
        
        // -------- removing attributes --------
        backingStorage.removeAttribute(.strikethroughStyle, range: editedRange)
        backingStorage.removeAttribute(.foregroundColor, range: editedRange)
        backingStorage.removeAttribute(.backgroundColor, range: editedRange)
        backingStorage.removeAttribute(.paragraphStyle, range: editedRange)
        
        backingStorage.mutableString.enumerateSubstrings(in: editedRange, options: [.byLines]) { (substring, range, enclosingRange, stop) in
            self.hightlight(in: backingStorage, line: substring!, inRange: range)
        }
    }
    
    /// Hightlight only one line.
    private func hightlight(in backingStorage: NSMutableAttributedString, line: String, inRange globalRange: NSRange) {
        
        let lineType = parser.lineType(of: line)
        
        switch lineType {
        case .other:
            backingStorage.addAttribute(.font, value: font, range: globalRange)
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalRange)
            backingStorage.addAttribute(.paragraphStyle, value: otherParagraphStyle, range: globalRange)
        case .header:
            backingStorage.addAttribute(.font, value: boldFont, range: globalRange)
            backingStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: globalRange)
            backingStorage.addAttribute(.paragraphStyle, value: headerParagraphStyle, range: globalRange)
        case .task:
            hightlightTask(in: backingStorage, line: line, at: globalRange)
        }
        
    }
    
    func hightlightTask(in backingStorage: NSMutableAttributedString, line: String, at globalRange: NSRange) {
        
        let shifting = globalRange.location
        
        guard let (prefixRange, markRange) = parser.taskMarkRange(in: line) else {
            fatalError("Invalid line type")
        }
        
        let indent = markRange.location
        
        backingStorage.addAttribute(.font, value: font, range: globalRange)
        
        let paragraphStyle = self.taskParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.firstLineHeadIndent = 24.0
        paragraphStyle.headIndent = CGFloat(24.0 * Double(indent) + 24.0)
        backingStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: globalRange)
            
        if parser.isCompleted(objectLine: line) {
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalRange)
            backingStorage.addAttribute(.prefix, value: Prefix.completed, range: markRange.shifted(by: shifting))
            backingStorage.addAttribute(.strikethroughStyle, value: 1, range: globalRange)
        } else {
            backingStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: globalRange)
            backingStorage.addAttributes([.foregroundColor : NSColor.orange], range: markRange.shifted(by: shifting))
            if let (_ , _, enclosingRange) = parser.ranges(for: "marked", in: line) {
                let markedRange = NSRange(location: prefixRange.upperBound, length: globalRange.length - prefixRange.upperBound).shifted(by: shifting)
                backingStorage.addAttribute(.backgroundColor, value: NSColor(calibratedRed: 229/255, green: 199/255, blue: 103/255, alpha: 0.4), range: markedRange)
                backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: enclosingRange.shifted(by: shifting))
            }
            
            
            let now = Date()
            
            if let (date , enclosingRange) = parser.parseDate(with: "start", in: line) {
                backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: enclosingRange.shifted(by: shifting))
                
                if now > date {
                    backingStorage.addAttribute(.backgroundColor, value: NSColor(calibratedRed: 229/255, green: 199/255, blue: 103/255, alpha: 0.4), range: globalRange)
                }
            }
            
            if let (date , enclosingRange) = parser.parseDate(with: "due", in: line) {
                backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: enclosingRange.shifted(by: shifting))
                if now > date {
                    backingStorage.addAttribute(.backgroundColor, value: NSColor(calibratedRed: 200/255, green: 154/255, blue: 240/255, alpha: 0.4), range: globalRange)
                }
            }
            
            
        }
        
        backingStorage.addAttribute(.foregroundColor, value: NSColor.separatorColor, range: prefixRange.shifted(by: shifting))
        
    }
    
    func highlightRoots(in textStorage: NSMutableAttributedString, inRange editedRange: NSRange) {
        
        let mutString = textStorage.mutableString
        
        var extendedRange = parser.extendedRange(in: mutString, for: editedRange)
        if extendedRange.location > 0 {
            let lookUpRange = NSRange(location: extendedRange.location - 1, length: 1)
            let previousLineRange = mutString.lineRange(for: lookUpRange)
            extendedRange = NSUnionRange(extendedRange, previousLineRange)
        }
        textStorage.removeAttribute(.prefix, range: extendedRange)
        
        var currentIndent: Int?
        // Don`t change next line after extendedRange.
        if extendedRange.upperBound < mutString.length {
            let lookDownRange = NSRange(location: extendedRange.upperBound, length: 1)
            let nextLineRange = mutString.lineRange(for: lookDownRange)
            let lastLine = mutString.substring(with: nextLineRange)
            if let prefixRange = parser.taskMarkRange(in: lastLine)?.prefix {
                currentIndent = prefixRange.upperBound
            }
        }
        
        // Look lines from bottom to top.
        textStorage.mutableString.enumerateSubstrings(in: extendedRange, options: [.byLines,.reverse]) { (substring, range, enclosingRange, stop) in
            
            let offset = range.location
            
            if let (prefixRange, markRange) = self.parser.taskMarkRange(in: substring!) {
                let newIndent = prefixRange.upperBound
                let shiftedMarkRange = markRange.shifted(by: offset)
                
                if let tempIndent = currentIndent, newIndent < tempIndent {
                    textStorage.addAttribute(.prefix, value: Prefix.root, range: shiftedMarkRange)
                } else {
                    if self.parser.isCompleted(objectLine: substring!){
                        textStorage.addAttribute(.prefix, value: Prefix.completed, range: shiftedMarkRange)
                    } else {
                        textStorage.addAttribute(.prefix, value: Prefix.task, range: shiftedMarkRange)
                    }
                }
                currentIndent = newIndent
            } else {
                // If find no task at line
                currentIndent = nil
            }
            
        }
    }
    
    func replace(_ backingStorage: NSMutableAttributedString, in editedRange: NSRange) {
        
        var extendedRange = parser.extendedRange(in: backingStorage.mutableString, for: editedRange)
        
        let replaceLine = { (backingStore: NSMutableAttributedString, line: String, range: NSRange) in
            if let (_ , _, enclosingRange) = self.parser.ranges(for: "test", in: line) {
                let attachment = NSTextAttachment()
                attachment.image = NSImage(imageLiteralResourceName: "uncompleted")
                let attrStr = NSAttributedString(attachment: attachment)
                backingStorage.replaceCharacters(in: enclosingRange.shifted(by: range.location), with: attrStr)
            }
        }
        
        backingStorage.mutableString.enumerateSubstrings(in: extendedRange, options: [.byLines]) { (substring, range, enclosingRange, stop) in
            replaceLine(backingStorage, substring!, range)
        }
    }
    
}
