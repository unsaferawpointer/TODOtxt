//
//  Parser.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

enum DateGranulity: Int {
    
    case day = 0, month, year
    var format: String {
        switch self {
        case .day:
            return "yyyy-MM-dd"
        case .month:
            return "yyyy-MM"
        case .year:
            return "yyyy"
        }
    }
    
    func date(from str: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.format
        return dateFormatter.date(from: str)
    }
    
    func string(from date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.format
        return dateFormatter.string(from: date)
    }
    
}

enum Element: Hashable {
    
    case status
    case priority
    case tag
    case dueDate(granulity: DateGranulity)
    case startDate(granulity: DateGranulity)
    
    var pattern: String {
        switch self {
        case .status:
            return #"^\t*(\[(x|\s|\-|[A-Z])\])\s.*"# //#"^((x)\s).+"#
        case .priority:
            return #"^^\t*(\[([A-Z]|\s)\])\s"#
        case .tag:
            return #"(\s#(\w+))\b"#
        case .dueDate(let granulity):
            switch granulity {
            case .year:
                return #"(@due\((19[0-9]{2}|2[0-9]{3}))\)\b"#
            case .month:
                return #"(@due\(((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])))\)\b"#
            case .day:
                return #"(@due\(((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])-([123]0|[012][1-9]|31)))\)\b"#
            } 
        case .startDate(let granulity):
            switch granulity {
            case .year:
                return #"(@start\((19[0-9]{2}|2[0-9]{3}))\)\b"#
            case .month:
                return #"(@start\(((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])))\)\b"#
            case .day:
                return #"(@start\(((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])-([123]0|[012][1-9]|31)))\)\b"#
            }
        }
    }
    
    func prefixString(for value: String) -> String {
        guard value.isEmpty == false else { return "" }
        switch self {
        case .status:
            return "x "
        case .priority:
            return "[\(value)] "
        case .tag:
            return " #\(value)"
        case .dueDate:
            return " @due(\(value))"
        case .startDate:
            return " @start(\(value))"
        }
    }
    
    func isValid(string: String) -> Bool {
        switch self {
        case .dueDate(granulity: .day):
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: string) != nil
        default:
            return true
        }
    }
    
}



enum DueDateType: Int {
    case none, overdue, today, tomorrow
}

class Parser {
    
    var font: NSFont
    var boldFont: NSFont
    
    var elements: Set<Element> = [.tag, .startDate(granulity: .day), .dueDate(granulity: .day)]
    var commonAttr:[NSAttributedString.Key: Any?]!
    
    // ********** Init block **********
    init() {
        self.font = NSFont(name: "IBM Plex Mono", size: 14.0)!
        self.boldFont = NSFont(name: "IBM Plex Mono Medium", size: 14.0)!
    }
    
}

// ********** Highlighting **********
extension Parser {
    
    func highlight(theme: Theme, backingStorage: NSMutableAttributedString, in extendedRange: NSRange) {
        backingStorage.mutableString.enumerateSubstrings(in: extendedRange, options: .byLines) { (substring, range, enclosingRange, stop) in
            self.hightlight(theme: theme, backingStorage: backingStorage, substring!, in: enclosingRange)
        }
    }
    
    private func hightlight(theme: Theme, backingStorage: NSMutableAttributedString, _ body: String, in globalBodyRange: NSRange) {
        
        let lineType = self.lineType(of: body)
        
        switch lineType {
        case .empty:
            //backingStorage.addAttribute(NSAttributedString.Key("isHeader"), value: 0, range: globalBodyRange)
            backingStorage.addAttribute(.font, value: font, range: globalBodyRange)
            return
        case .header:
            
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.alignment = .left
            paragraphStyle.paragraphSpacing = 8.0
            backingStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: globalBodyRange)
           
            backingStorage.addAttribute(.font, value: boldFont, range: globalBodyRange)
            backingStorage.addAttribute(.kern, value: 1.0, range: globalBodyRange)
            backingStorage.addAttribute(.strikethroughStyle, value: 0, range: globalBodyRange)
            backingStorage.addAttribute(.foregroundColor, value: NSColor.headerTextColor, range: globalBodyRange)
            return
        case .task:
            
            backingStorage.addAttribute(.font, value: font, range: globalBodyRange)
            break
        case .text:
            let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.firstLineHeadIndent = 14.0
            paragraphStyle.headIndent = 14.0
            paragraphStyle.paragraphSpacing = 4.0
            
            backingStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: globalBodyRange)
            backingStorage.addAttribute(.font, value: font, range: globalBodyRange)
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalBodyRange)
            return
        }
        
        
        let task = parseTask(for: body)!
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.firstLineHeadIndent = 14.0
        paragraphStyle.headIndent = 14.0
        paragraphStyle.defaultTabInterval = 14.0
        //paragraphStyle.tabStops = [NSTextTab(type: .leftTabStopType, location: 42.0),NSTextTab(type: .leftTabStopType, location: 70.0),NSTextTab(type: .leftTabStopType, location: 98.0),NSTextTab(type: .leftTabStopType, location: 136.0)]
        
        paragraphStyle.paragraphSpacing = 4.0
        
        backingStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: globalBodyRange)
        
        
        if task.isCompleted {
            
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalBodyRange)
            backingStorage.addAttribute(.strikethroughStyle, value: 1, range: globalBodyRange)
            
        } else {
            
            backingStorage.addAttribute(.strikethroughStyle, value: 0, range: globalBodyRange)
            backingStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: globalBodyRange)
            
            if let (range, enclosingRange) = parse(.status, inLine: body, with: globalBodyRange.location) {
                backingStorage.addAttributes([.foregroundColor : NSColor.color(hex: "#D38844")!], range: enclosingRange)
            }
            
            for element in elements {
                if let (range, enclosingRange) = parse(element, inLine: body, with: globalBodyRange.location) {
                    
                    backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
                }
            }
            
            
        }
        
       
    }
    
}

// ********** PARSING DATA **********
extension Parser {
    
    // ********** Common ********
    
    enum LineType: Int {
        case empty = 0, task, header, text
    }
    
    func lineType(of body: String) -> LineType {
        guard body.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else { return .empty }
        let pattern = #"^#.+\:$"#
        let range = body.fullRange
        let regex = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        if regex.firstMatch(in: body, options: [], range: range) != nil {
            return .header
        }
        
        let taskPattern = #"^\t*(\[(x|\s|\-|[A-Z])\])\s.*"#
        let taskRegex = try! NSRegularExpression(pattern: taskPattern, options: .anchorsMatchLines)
        if taskRegex.firstMatch(in: body, options: [], range: range) != nil {
            return .task
        }
        
        return .text
    }
    
    
    func parse(string: String) -> [Task] {
        var array = [Task]()
        string.enumerateLines { (substring, stop) in
            if let task = self.parseTask(for: substring) {
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
    
    func parse(_ mutString: NSMutableString, in editedRange: NSRange) -> [Task] {
        
        var array = [Task]()
        mutString.enumerateSubstrings(in: editedRange, options: .byLines) { (substring, substringRange, enclosingRange, stop) in
            if let body = substring, let task = self.parseTask(for: body)  {
                array.append(task)
            }
        }
        
        return array
    }
    
    // WARNING ambiguous func name
    // parsing todo
    func parseTask(for line: String) -> Task? {
        
        guard isTask(line) else { return nil}
        
        let hashtag = stringValue(in: line, for: .tag)
        //let priority = parse(in: body, element: .priority)
        let dueDateStr = stringValue(in: line, for: .dueDate(granulity: .day))
        let startDateStr = stringValue(in: line, for: .startDate(granulity: .day))
        let statusString = stringValue(in: line, for: .status)
        
        let (_, enclosingRange) = parse(.status, inLine: line)!
        let bodyRange = NSRange(location: enclosingRange.upperBound, length: line.count - enclosingRange.length)
        let body = line.substring(from: bodyRange).trimmingCharacters(in: .whitespaces)
        
        precondition(statusString != nil, "The status can`t be equals nil")
        
        var dueDate: NSDate?
        var startDate: NSDate?
        var status: StatusType = .uncompleted
        
        // WARNING
        if let dateStr = dueDateStr {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = DateGranulity.day.format
            dueDate = dateFormatter.date(from: dateStr)! as NSDate
        }
        
        // WARNING
        if let dateStr = startDateStr {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = DateGranulity.day.format
            startDate = dateFormatter.date(from: dateStr)! as NSDate
        }
        
        switch statusString! {
        case "x":
            status = .completed
        case "-":
            status = .canceled
        case " ":
            status = .uncompleted
        default:
            status = .uncompleted
        }
            
        
        let task = Task(string: line, body: body, status: status, dueDate: dueDate, startDate: startDate)
        
        return task
    }
    
    func isTask(_ body: String) -> Bool {
        return lineType(of: body) == .task
    }
    
    func stringValue(in body: String, for element: Element) -> String? {
        if let range = parse(element, inLine: body)?.range {
            let nsstring = body as NSString
            return nsstring.substring(with: range)
        } else { 
            return nil
        }
    }
    
    func parse(_ pattern: String, in body: String, with shift: Int = 0) -> NSRange? {
        let range = NSString(string: body).range(of: body)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        if let match = regex.firstMatch(in: body, options: [], range: range) {
            var range = match.range
            range.location += shift
            return range
        }
        
        return nil
    }
    
    func parse(_ element: Element, inLine line: String, with shift: Int = 0) -> (range: NSRange, enclosingRange: NSRange)? {
        let pattern = element.pattern
        let range = NSString(string: line).range(of: line)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        if let match = regex.firstMatch(in: line, options: [], range: range) {
            
            var range = match.range(at: 2)
            // Element validation
            let str = line.substring(from: range)
            guard element.isValid(string: str) else { return nil }
            
            range.location += shift
            
            var enclosingRange = match.range(at: 1)
            enclosingRange.location += shift
            
            return (range, enclosingRange)
        }
        
        return nil
    }
    
    func detectFirst(elements: [Element], in string: String, beginAt location: Int, forSelectionAt index: Int) -> (element: Element, range: NSRange, enclosingRange: NSRange)? {
        for element in elements {
            if let (range, enclosingRange) = parse(element, inLine: string, with: location) {
                if range.contains(index) || range.upperBound == index { return (element, range, enclosingRange) }
            }
        }
        return nil
    }
    
}

// =====================
// REPLACING 
// =====================

extension Parser {
    
    func tailLine(substring: String, with shift: Int) -> (editedRange: NSRange, lastSymbolRange: NSRange)? {
        let pattern = #"(.)$"#
        let range = NSString(string: substring).range(of: substring)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        if let match = regex.firstMatch(in: substring, options: [], range: range) {
            var range = match.range(at: 1)
            range.location += shift
            let editedRange = NSRange(location: range.upperBound, length: 0)
            return (editedRange: editedRange, lastSymbolRange: range)
        }
        
        return nil
    }
    
    func headerLine(substring: String, with shift: Int) -> NSRange? {
        let pattern = #"^\s*"#
        return parse(pattern, in: substring, with: shift)
    }
    
}

enum DateStyle: Int, CaseIterable {
    case day = 0, month, year, common
    var title: String {
        switch self {
        case .common:
            return "by default"
        case .day:
            return "by day"
        case .month:
            return "by month"
        case .year:
            return "by year"
        }
    }
}



