//
//  Parser.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum TaskStatus: Equatable {
    case uncompleted
    case completed
}

struct ObjectDate {
    
    let date: Date
    let granulity: DateGranulity
    
    init(date: Date, granulity: DateGranulity) {
        self.date = date
        self.granulity = granulity
    }
    
}

enum DatePrefix: String {
    case due
    case at
    case threshold
}

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

class Parser {
    
    
    func parseGroups(backingStorage: NSMutableAttributedString) {
        var indent: Int?
        let fullRange = backingStorage.mutableString.fullRange
        print(#function)
        
        backingStorage.mutableString.enumerateSubstrings(in: fullRange, options: [.reverse, .byLines]) { (substring, range, enclosingRange, stop) in
            print("- - - - - - - -")
            print(substring)
            print("oldIndent = \(indent)")
            backingStorage.addAttribute(.prefix, value: 0, range: enclosingRange)
            if let statusRange = self.ranges(for: "done", in: substring!)?.statusRange {
                if let i = indent, statusRange.location < i {
                    print("isRoot")
                    
                    //backingStorage.addAttribute(.foregroundColor, value: NSColor.red, range: statusRange.shifted(by: range.location))
                    //backingStorage.addAttributes([.prefix : 1], range: statusRange.shifted(by: range.location))
                } 
                indent = statusRange.location
                print("newIndent = \(indent)")
            } else {
                indent = nil
                print("indent = nil")
            }
        }
    }

}

// ********** PARSING DATA **********
extension Parser {
    
    // ********** Common ********
    
    enum LineType: Int, CaseIterable {
        
        case empty = 0
        case task
        case event
        case header
        case other
        
        var pattern: String? {
            switch self {
            case .empty:
                return #"^\s*$"#
            case .task:
                return #"^(\t*)(\*|-)\s"#
            case .event:
                return #"^(>)\s"#
            case .header:
                return #"^#\s.+"#
            case .other:
                return nil
            }
        }
        
    }
    
    
    func lineType(of line: String) -> LineType {
        
        let range = line.fullRange
        
        for type in LineType.allCases {
            if let pattern = type.pattern {
                let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
                if regex.firstMatch(in: line, options: [], range: range) != nil {
                    return type
                }
            }
        }
        
        return .other
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
    
    // parse text while reading a document
    func parse(text: NSMutableString) -> [Task]  {
        
        let range = text.fullRange
        return parse(text, in: range)
        
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
    
    /// Parsing task. 
    func parseTask(in line: String, validateType: Bool) -> Task? {
        
        if validateType {
            let lineType = self.lineType(of: line)
            print(lineType)
            guard lineType == .task else {
                return nil 
            }
        }
        
        let markRange = self.objectMarkRange(in: line)!
        let indent = markRange.location // /t/t* task body 
        
        let isCompleted = self.isCompleted(objectLine: line)
        
        let dueTuple = parseDate(with: .due, inObjectLine: line)
        let due = dueTuple?.date
        
        let tresholdTuple = parseDate(with: .threshold, inObjectLine: line)
        let treshold = tresholdTuple?.date
        
        let hashtag = parseHashtag(in: line)?.hashtag
        
        // WARNING TEST Add calculationg body
        let task = Task.init(string: line, body: line, isCompleted: isCompleted, hashtag: hashtag, dueDate: due, startDate: treshold, indent: indent)
        
        return task
    }
    
    
    /// Parsing event.
    func parseEvent(in line: String, validateType: Bool) -> Event? {
        
        if validateType {
            let lineType = self.lineType(of: line)
            guard lineType == .event else {
                return nil 
            }
        }
        
        // Every event must have a date
        guard let date = parseEventDate(inEventLine: line)?.date else {
            return nil
        }
        
        let isCancelled =  has(keyWord: "cancelled", in: line)
        let hashtag = parseHashtag(in: line)?.hashtag
        
        // TEST isCancelled = false
        let event = Event(line, isCancelled: isCancelled, at: date, hashtag: hashtag)
        return event
    }
    
    /// parsing line object
    func parseLineObject(for line: String) -> LineObject? {
        
        let type = lineType(of: line)
        guard type == .task || type == .event else {
            return nil
        }
        
        switch type {
        case .task:
            return parseTask(in: line, validateType: false)
        case .event:
            return parseEvent(in: line, validateType: false)
        default:
            return nil
        }
    
    }
    
    
    func isTask(_ body: String) -> Bool {
        return lineType(of: body) == .task
    }
    
    // ******** Parsing tokens ********
    
    // -------- common function --------
    
    func textCheckingResult(for pattern: String, in line: String) -> NSTextCheckingResult? {
        let range = (line as NSString).range(of: line)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        return regex.firstMatch(in: line, options: [], range: range)
    }
    
    // -------- hashtag --------
    
    func parseHashtag(in line: String) -> (hashtag: String, prefixRange: NSRange, wordRange: NSRange, enclosingRange: NSRange)? {
        if let (prefixRange, wordRange, enclosingRange) = hashtagRange(in: line) {
            let value = line.substring(from: wordRange)
            return (value, prefixRange, wordRange, enclosingRange)
        }
        return nil
    }
    
    func hashtagRange(in line: String) -> (prefixRange: NSRange, wordRange: NSRange, enclosingRange: NSRange)? {
        let pattern = #"(\s?(#)(\w+)\s?)"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let prefixRange = match.range(at: 2)
            let wordRange = match.range(at: 3)
            let enclosingRange = match.range(at: 1)
            return (prefixRange, wordRange, enclosingRange)
        }
        return nil
    }
    
    func detectHashtag(in line: String, beginAt stringLocation: Int, forSelectionAt selectionLocation: Int) -> (range: NSRange, enclosingRange: NSRange)? {
        let nSelLocation = selectionLocation - stringLocation
        if let (prefixRange, wordRange, enclosingRange) = hashtagRange(in: line) {
            if prefixRange.upperBound >= nSelLocation && wordRange.upperBound <= nSelLocation { 
                return (wordRange, enclosingRange)
            }
        }
        return nil
    }
    
    // -------- task priority --------
    
    func objectMarkRange(in line: String) -> NSRange? {
        let pattern = #"^(\t*)(\*|-|>)\s"#
        if let match = textCheckingResult(for: pattern, in: line) {
            return match.range(at: 2)
        }
        return nil
    }
    
    /// Input line must have only task line type
    func isCompleted(objectLine line: String) -> Bool {
        return ranges(for: "done", in: line) != nil
    }
    
    func has(keyWord word: String, in line: String) -> Bool {
        return ranges(for: word, in: line) != nil
    }
    
    func ranges(for keyWord: String, in line: String) -> (prefixRange: NSRange, statusRange: NSRange, enclosingRange: NSRange)? {
        
        let pattern = "(@)(\(keyWord))"
        if let match = textCheckingResult(for: pattern, in: line) {
            let prefixRange = match.range(at: 1)
            let statusRange = match.range(at: 2)
            let enclosingRange = match.range
            return (prefixRange, statusRange, enclosingRange)
        }
        return nil
    }
    
    // -------- parse date --------
    
    /// Parsing event date ranges with date validation.
    func parseEventDate(inEventLine line: String) -> (date: ObjectDate, timeRange: NSRange, dateRange: NSRange)? {
        
        if let (timeRange, dateRange, timeDateRange) = eventDateRange(inLineObject: line) {
            let str = line.substring(from: timeDateRange)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm yyyy-MM-dd"
            if let date = dateFormatter.date(from: str) {
                print("date = \(date)")
                return (ObjectDate(date: date, granulity: .time), timeRange, dateRange)
            }
        }
        
        return nil
    }
    
    /// Parsing ranges w/o date validation
    func eventDateRange(inLineObject line: String) -> (timeRange: NSRange, dateRange: NSRange, timeDateRange: NSRange)? {
        
        let pattern = #"^\>\s((([01][0-9]|2[0-3]):([0-5][0-9])) ((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])-([123]0|[012][1-9]|31)))"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let timeDateRange = match.range(at:1)
            let timeRange = match.range(at:2)
            let dateRange = match.range(at:5)
            
            return (timeRange, dateRange, timeDateRange)
        }
        return nil
    }
    
    ///Ranges w/o date validation.  Enclosing range include prefix and date. Example "@due(2019-10-10 11:30)"
    func dateRange(with prefix: DatePrefix, inObjectLine line: String) -> (dateTimeRange: NSRange, enclosingRange: NSRange)? {
        let pattern = "(@\(prefix.rawValue)\\((.+?)\\))"
        if let match = textCheckingResult(for: pattern, in: line) {
            let dateTimeRange = match.range(at: 2)
            let enclosingRange = match.range(at: 1)
            return (dateTimeRange, enclosingRange)
        }
        return nil
    }
    
    func parseDate(with prefix: DatePrefix, inObjectLine line: String) -> (date: ObjectDate, enclosingRange: NSRange)? {
        
        let array: [DateGranulity] = [.day, .month, .year, .time]
        if let (dateTimeRange, enclosingRange) = dateRange(with: prefix, inObjectLine: line) {
            let str = line.substring(from: dateTimeRange)
            let dateFormatter = DateFormatter()
            for granulity in array {
                dateFormatter.dateFormat = granulity.format
                if let date = dateFormatter.date(from: str) {
                    return (ObjectDate(date: date, granulity: granulity), enclosingRange)
                }
            }
        }
        
        return nil
    }
    
    
}







