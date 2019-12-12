//
//  Parser.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum DateGranulity: Int {
    
    case day = 0, month, year, time
    
    var format: String {
        switch self {
        case .day:
            return "yyyy-MM-dd"
        case .month:
            return "yyyy-MM"
        case .year:
            return "yyyy"
        case .time:
            return "yyyy-MM-dd hh:mm"
        }
    }
    
}

enum LineType: Int, CaseIterable {
    
    case task
    case header
    case other
    
}

class Parser {
    
    // ********** Common ********
    
    func lineType(of line: String) -> LineType {
        
        if let _ = taskMarkRange(in: line) {
            return .task
        } else if let _ = headerMarkRange(in: line) {
            return .header
        }
        
        return .other
    }
    
    func isTask(_ body: String) -> Bool {
        return lineType(of: body) == .task
    }
    
    // ******** PARSING OBJECTS ********
    
    /// Parsing task. 
    func parseTask(in line: String, validateType: Bool) -> Task? {
        fatalError("Dont implemented")
        return nil
    }
    
    func parse(string: String) -> [Task] {
        var array = [Task]()
        string.enumerateLines { (substring, stop) in
            if let task = self.parseTask(in: substring, validateType: true) {
                array.append(task)
            }
        }
        return array
    }
    
    /// Parse string to [Task], where task.tasks.isEmpty == true
    func parse(_ mutString: NSMutableString, in editedRange: NSRange) -> [Task] {
        
        var array = [Task]()
        mutString.enumerateSubstrings(in: editedRange, options: .byLines) { (substring, substringRange, enclosingRange, stop) in
            if let body = substring, let task = self.parseTask(in: body, validateType: true) {
                array.append(task)
            }
        }
        
        return array
    }
    
    
    // ******** Parsing tokens ********
    
    // -------- common function --------
    
    func textCheckingResult(for pattern: String, in line: String) -> NSTextCheckingResult? {
        let range = NSRange(location:0, length: (line as NSString).length)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        return regex.firstMatch(in: line, options: [], range: range)
    }
    
    func extendedRange(in mutString: NSMutableString, for editedRange: NSRange) -> NSRange {
        let firstLineRange = mutString.lineRange(for: editedRange)
        let extendedRange = NSRange(location: editedRange.upperBound, length: 0)
        let lastLineRange = mutString.lineRange(for: extendedRange)
        let finalRange = NSUnionRange(firstLineRange, lastLineRange)
        return finalRange
    }
    
    /// editedRange must be in single line, overwhise return nil
    func lookDownRange(_ mutString: NSMutableString, editedRange: NSRange) -> NSRange? {
        
        // Must be a single line
        guard let singleLineRange = mutString.singleLine(for: editedRange) else { return nil }
        let singleLine = mutString.substring(with: singleLineRange)
        // Must be a task
        guard let (prefixRange, _) = taskMarkRange(in: singleLine) else { return nil }
        let startIndent: Int = prefixRange.upperBound
        print("startIndent = \(startIndent)")
        
        let lookDownRange = NSRange(location: singleLineRange.upperBound, length: mutString.length - singleLineRange.upperBound)
        var result: NSRange?
        
        mutString.enumerateSubstrings(in: lookDownRange, options: .byLines) { (line, range, enclosingRange, stop) in
            if let (prefixRange, _ ) = self.taskMarkRange(in: line!) {
                let indent = prefixRange.upperBound
                print("indent = \(indent)")
                if indent > startIndent {
                    if let extendedRange = result {
                        result = extendedRange.union(range)
                    } else {
                        result = range
                    }
                } else {
                    stop.pointee = ObjCBool(true)
                }
            } else {
                stop.pointee = ObjCBool(true)
            }
            print("resultRange = \(result)")
        }
        
        return result
    }
    
    /// Return emty range before /n
    func lineTail(for line: String) -> NSRange? {
        let pattern = "$"
        if let match = textCheckingResult(for: pattern, in: line) {
            let enclosingRange = match.range
            return enclosingRange
        }
        return nil
    }
    
    // ******** mark for object, header ********
    
    func taskMarkRange(in line: String) -> (prefix: NSRange, mark: NSRange)? {
        let pattern = #"^(\t*)(-)\s"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let prefixRange = match.range(at: 1)
            let markRange = match.range(at: 2)
            return (prefixRange, markRange)
        }
        return nil
    }
    
    func headerMarkRange(in line: String) -> NSRange? {
        let pattern = #"(#)\s"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let markRange = match.range(at: 1)
            return markRange
        }
        return nil
    }
    
    func isCompleted(objectLine line: String) -> Bool {
        return has(keyWord: "done", in: line)
    }
    
    func has(keyWord: String, in line: String) -> Bool {
        return ranges(for: keyWord, in: line) != nil
    }
    
    /// Return ranges of the regular expression like a "@keyword". Return first regex in the line.
    func ranges(for keyWord: String? = nil, in line: String) -> (prefixRange: NSRange, wordRange: NSRange, enclosingRange: NSRange)? {
        
        let pattern = "\\B(@)(\(keyWord ?? "\\w+"))\\b"
        
        if let match = textCheckingResult(for: pattern, in: line) {
            let prefixRange = match.range(at: 1)
            let wordRange = match.range(at: 2)
            let enclosingRange = match.range
            return (prefixRange, wordRange, enclosingRange)
        }
        
        return nil
    }
    
    // -------- parse date --------
    
    func parseDate(with keyWord: String, in line: String) -> (date: Date, enclosingRange: NSRange)? {
        let pattern = "@\(keyWord)\\((.+?)\\)"
        
        if let match = textCheckingResult(for: pattern, in: line) {
            let dateRange = match.range(at: 1)
            let enclosingRange = match.range
            let str = line.substring(from: dateRange)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: str) {
                return (date, enclosingRange)
            }
            
        }
        return nil
    }
    
    
}







