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
    
    var textParagraphStyle: NSMutableParagraphStyle
    var taskParagraphStyle: NSMutableParagraphStyle
    var headerParagraphStyle: NSMutableParagraphStyle
    
    var parser: Parser
    
    init() {
        self.parser = Parser()
        self.font = NSFont(name: "IBM Plex Mono", size: 14.0)!
        self.boldFont = NSFont(name: "IBM Plex Mono Medium", size: 14.0)!
        
        self.textParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        self.textParagraphStyle.firstLineHeadIndent = 24.0
        self.textParagraphStyle.headIndent = 24.0
        self.textParagraphStyle.paragraphSpacing = 4.0
        
        
        self.headerParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        self.headerParagraphStyle.alignment = .left
        //self.headerParagraphStyle.paragraphSpacing = 8.0
        
        self.taskParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        //self.taskParagraphStyle.firstLineHeadIndent = 14.0
        self.taskParagraphStyle.paragraphSpacing = 4.0
        self.textParagraphStyle.firstLineHeadIndent = 24.0
        self.taskParagraphStyle.defaultTabInterval = 24.0
        self.taskParagraphStyle.tabStops = [NSTextTab(type: .leftTabStopType, location: 14.0)]
    }
    
    init(parser: Parser) {
        self.parser = parser
        self.font = NSFont(name: "IBM Plex Mono", size: 14.0)!
        self.boldFont = NSFont(name: "IBM Plex Mono Medium", size: 14.0)!
        
        self.textParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        self.textParagraphStyle.firstLineHeadIndent = 24.0
        self.textParagraphStyle.headIndent = 24.0
        self.textParagraphStyle.paragraphSpacing = 4.0
        
        
        self.headerParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        self.headerParagraphStyle.alignment = .left
        //self.headerParagraphStyle.paragraphSpacing = 8.0
        
        self.taskParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        //self.taskParagraphStyle.firstLineHeadIndent = 14.0
        self.taskParagraphStyle.paragraphSpacing = 4.0
        self.textParagraphStyle.firstLineHeadIndent = 24.0
        self.taskParagraphStyle.defaultTabInterval = 24.0
        self.taskParagraphStyle.tabStops = [NSTextTab(type: .leftTabStopType, location: 14.0)]
    }
    
    func highlight(theme: Theme, backingStorage: NSMutableAttributedString, in extendedRange: NSRange) {
        var indent: Int?
        backingStorage.removeAttribute(.prefix, range: extendedRange)
        backingStorage.mutableString.enumerateSubstrings(in: extendedRange, options: [.byLines,.reverse]) { (substring, range, enclosingRange, stop) in
            
            let shifting = range.location
            if let (status, statusRange) = self.hightlight(theme: theme, backingStorage: backingStorage, substring!, in: enclosingRange) {
                let newIndent = statusRange.location
                if status == .completed {
                    backingStorage.addAttribute(.prefix, value: Prefix.completed, range: statusRange.shifted(by: shifting))
                } else {
                    if indent != nil && newIndent < indent! {
                        print("isRoot")
                        //backingStorage.addAttribute(.prefix, value: Prefix.root, range: statusRange.shifted(by: shifting))
                    } else {
                        print("isTask")
                        //backingStorage.addAttribute(.prefix, value: Prefix.task, range: statusRange.shifted(by: shifting))
                    }
                }
                indent = newIndent
            } else {
                print("it is not task")
                indent = nil
            }
        }
    }
    
    private func hightlight(theme: Theme, backingStorage: NSMutableAttributedString, _ line: String, in globalBodyRange: NSRange) -> (TaskStatus, NSRange)? {
        
        let lineType = parser.lineType(of: line)
        
        // -------- removing attributes --------
        backingStorage.removeAttribute(.strikethroughStyle, range: globalBodyRange)
        backingStorage.removeAttribute(.foregroundColor, range: globalBodyRange)
        backingStorage.removeAttribute(.paragraphStyle, range: globalBodyRange)
        backingStorage.addAttribute(.font, value: font, range: globalBodyRange)
        backingStorage.removeAttribute(.prefix, range: globalBodyRange)
        
        print(lineType)
        switch lineType {
        case .other, .empty:
            backingStorage.addAttribute(.paragraphStyle, value: textParagraphStyle, range: globalBodyRange)
            return nil
        case .header:
            backingStorage.addAttribute(.paragraphStyle, value: headerParagraphStyle, range: globalBodyRange)
            return nil
        case .event:
            hightlightEvent(theme: theme, backingStorage: backingStorage, line, in: globalBodyRange)
            return nil
        case .task:
            hightlightTask(theme: theme, backingStorage: backingStorage, line, in: globalBodyRange)
            return nil
        }
        
    }
    
    func hightlightTask(theme: Theme, backingStorage: NSMutableAttributedString, _ body: String, in globalBodyRange: NSRange) {
        
        let shifting = globalBodyRange.location
        
        guard let markRange = parser.objectMarkRange(in: body) else {
            fatalError("Invalid line type")
        }
            
        let indent = markRange.location
        
        let paragraphStyle = self.taskParagraphStyle.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.headIndent = CGFloat(24.0 * Double(indent) + 24.0)
        paragraphStyle.defaultTabInterval = 24.0
        paragraphStyle.firstLineHeadIndent = 24.0
        paragraphStyle.tabStops = [NSTextTab(type: .leftTabStopType, location: 48.0)]
        backingStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: globalBodyRange)
            
        let prefixRange = NSRange(location: shifting, length: indent)
        backingStorage.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: prefixRange)
            
        if parser.isCompleted(objectLine: body) {
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalBodyRange)
            backingStorage.addAttribute(.prefix, value: Prefix.completed, range: markRange.shifted(by: shifting))
            backingStorage.addAttribute(.strikethroughStyle, value: 1, range: globalBodyRange)
                
        } else {
            backingStorage.addAttributes([.foregroundColor : NSColor.orange], range: markRange.shifted(by: shifting))
                
        }
        
        if let enclosingRange = parser.parseHashtag(in: body)?.enclosingRange.shifted(by: shifting) {
             backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
         }
         
        if let enclosingRange = parser.parseDate(with: .due, inObjectLine: body)?.enclosingRange.shifted(by: shifting) {
             backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
         }
        
        if let enclosingRange = parser.parseDate(with: .threshold, inObjectLine: body)?.enclosingRange.shifted(by: shifting) {
             backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
         }
         
        if let enclosingRange = parser.parseDate(with: .at, inObjectLine: body)?.enclosingRange.shifted(by: shifting) {
             backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
         }
        
        
    }
    
    func hightlightEvent(theme: Theme, backingStorage: NSMutableAttributedString, _ body: String, in globalBodyRange: NSRange) {
        
        let shifting = globalBodyRange.location
        
        guard let markRange = parser.objectMarkRange(in: body) else {
            fatalError("Invalid line type")
        }
        
        backingStorage.addAttribute(.paragraphStyle, value: textParagraphStyle, range: globalBodyRange)
        backingStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: globalBodyRange)
        //backingStorage.addAttribute(.font, value: boldFont, range: globalBodyRange)
        
        if parser.isCompleted(objectLine: body) {
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalBodyRange)
        } else {
            backingStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: markRange.shifted(by: shifting))
        }
        
        if let enclosingRange = parser.parseHashtag(in: body)?.enclosingRange.shifted(by: shifting) {
            backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
        }
                   
        if let (date, timeRange, dateRange) = parser.parseEventDate(inEventLine: body) {
            print("dateRange = \(dateRange)")
            backingStorage.addAttributes([.foregroundColor : NSColor.systemBlue], range: timeRange.shifted(by: shifting))
            backingStorage.addAttributes([.foregroundColor : NSColor.systemBlue], range: dateRange.shifted(by: shifting))
        }
               
    }
    
}
