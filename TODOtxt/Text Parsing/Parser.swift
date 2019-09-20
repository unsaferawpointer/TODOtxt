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
    case project
    case context
    case date(granulity: DateGranulity)
    
    var rawValue: String {
        switch self {
        case .status:
            return "status"
        case .priority:
            return "priority"
        case .project:
            return "project"
        case .context:
            return "context"
        case .date(granulity: .day):
            return "date_day"
        case .date(granulity: .month):
            return "date_month"
        case .date(granulity: .year):
            return "date_year"
        }
    }
    
    /// Init by elementKey
    init? (rawValue: String) {
        switch rawValue {
        case "status":
            self = .status
        case "priority":
            self = .priority
        case "project":
            self = .project
        case "context":
            self = .context
        case "date_day":
            self = .date(granulity: .day)
        case "date_month":
            self = .date(granulity: .month)
        case "date_year":
            self = .date(granulity: .year)
        default:
            return nil
        }
    }
    
    var pattern: String {
        switch self {
        case .status:
            return #"^((x)\s).+"#
        case .priority:
            return #"^(?:x\s)?(\(([A-Z])\)\s)"#
        case .project:
            return #"(\s\+(\w+))\b"#
        case .context:
            return #"(\s\@(\w+))\b"#
        case .date(let granulity):
            switch granulity {
            case .year:
                return #"(\sdue\:(19[0-9]{2}|2[0-9]{3}))\b"#
            case .month:
                return #"(\sdue\:((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])))\b"#
            case .day:
                return #"(\sdue\:((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])-([123]0|[012][1-9]|31)))\b"#
            } 
        }
    }
    
    func prefixString(for value: String) -> String {
        guard value.isEmpty == false else { return "" }
        switch self {
        case .status:
            return "x "
        case .priority:
            return "(\(value)) "
        case .project:
            return " +\(value)"
        case .context:
            return " @\(value)"
        case .date:
            return " due:\(value)"
        }
    }
    
    func isValid(string: String) -> Bool {
        switch self {
        case .date(granulity: .day):
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter.date(from: string) != nil
        default:
            return true
        }
    }
    
}

class Parser {
    
    var font: NSFont
    var boldFont: NSFont
    
    
    
    var elements: Set<Element> = [.status, .project, .context, .date(granulity: .day), .priority]
    var commonAttr:[NSAttributedString.Key: Any?]!
    
    // ********** Init block **********
    init(font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)) {
        self.font = font
        
        let fontManager = NSFontManager()
        self.boldFont = fontManager.convert(font, toHaveTrait: .boldFontMask)
    }
    
}

// ********** Highlighting **********
extension Parser {
    
    func highlight(theme: Theme, backingStorage: NSMutableAttributedString, in extendedRange: NSRange) {
        backingStorage.mutableString.enumerateSubstrings(in: extendedRange, options: .byLines) { (substring, range, enclosingRange, stop) in
            self.hightlight(theme: theme, backingStorage: backingStorage, substring!, in: range)
        }
    }
    
    private func hightlight(theme: Theme, backingStorage: NSMutableAttributedString, _ body: String, in globalBodyRange: NSRange) {
        
        guard hasTodo(body) else { return }
        
        let completed = (parse(.status, inLine: body) != nil )
        
        if completed {
            
            backingStorage.addAttribute(.foregroundColor, value: theme.completed, range: globalBodyRange)
            backingStorage.addAttribute(.strikethroughStyle, value: 1, range: globalBodyRange)
            
        } else {
            
            let foregroundColor = theme.foreground
            backingStorage.addAttribute(.strikethroughStyle, value: 0, range: globalBodyRange)
            backingStorage.addAttribute(.foregroundColor, value: foregroundColor, range: globalBodyRange)
            
            var set = elements
            set.remove(.priority)
            
            for element in elements {
                if let range = parse(element, inLine: body, at: globalBodyRange.location)?.enclosingRange {
                    let color = theme.color(for: element)
                    backingStorage.addAttributes([.foregroundColor : color], range: range)
                    //backingStorage.addAttributes([.font : font], range: range)
                }
            }
            
        }
        
       
        
        
    }
    
}

// ********** PARSING DATA **********
extension Parser {
    
    func parse(_ string: String) -> [Task] {
        var array = [Task]()
        string.enumerateLines { (substring, stop) in
            if let task = self.parse(substring) {
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
            if let body = substring, let task = self.parse(body)  {
                array.append(task)
            }
        }
        
        return array
    }
    
    // WARNING ambiguous func name
    // parsing todo
    func parse(_ body: String) -> Task? {
        
        guard hasTodo(body) else { return nil}
        
        let project = parse(in: body, element: .project)
        let context = parse(in: body, element: .context)
        let priority = parse(in: body, element: .priority)
        let dateString = parse(in: body, element: .date(granulity: .day))
        let status = parse(in: body, element: .status)
        
        var dueDate: NSDate?
        
        // WARNING
        if let dateStr = dateString {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = DateGranulity.day.format
            dueDate = dateFormatter.date(from: dateStr)! as NSDate
        }
            
        
        let task = Task(string: body, status: status, project: project, context: context, priority: priority, dateString: dateString, dueDate: dueDate)
        
        return task
    }
    
    func hasTodo(_ body: String) -> Bool {
        let result = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.count > 0
    }
    
    
    func parse(in body: String, element: Element) -> String? {
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
    
    
    func parse(_ element: Element, inLine body: String, at shift: Int = 0) -> (range: NSRange, enclosingRange: NSRange)? {
        let pattern = element.pattern
        let range = NSString(string: body).range(of: body)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        if let match = regex.firstMatch(in: body, options: [], range: range) {
            
            var range = match.range(at: 2)
            // Element validation
            let str = body.substring(from: range)
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
            if let (range, enclosingRange) = parse(element, inLine: string, at: location) {
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



