//
//  Parser.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa
/*
 #"(@due\((19[0-9]{2}|2[0-9]{3}))\)\b"#
 case .month:
     return #"(@due\(((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])))\)\b"#
 case .day:
     return #"(\B@due\(((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])-([123]0|[012][1-9]|31))\s\)\B)"#
 case .time:
     return #"(\B@due\(((19[0-9]{2}|2[0-9]{3})-(0[1-9]|1[012])-([123]0|[012][1-9]|31))\s((0[0-9]|1[0-9]|2[0-4]):([0-5][0-9]))\)\B)"#
 */


   
   
   /*
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
   
   func parse(_ element: Token, inLine line: String, with shift: Int = 0) -> (range: NSRange, enclosingRange: NSRange)? {
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
*/


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

enum Token: Hashable {
    
    case type
    case priority
    case dueDate
    case startDate
    case tag
    
    var pattern: String {
        switch self {
        case .type:
            return #"^\t*(\[(x|\s|\-|[A-Z])\])\s.*"# //#"^((x)\s).+"#
        case .priority:
            return #"^^\t*(\[([A-Z]|\s)\])\s"#
        case .dueDate:
            return #"\B(@due\((.+?)\))\B"#
        case .startDate:
            return #"\B(@start\((.+?)\))\B"#
        case .tag:
            return #"(\s#(\w+))\b"#
        }
    }
    
    func prefixString(for value: String) -> String {
        guard value.isEmpty == false else { return "" }
        switch self {
        case .type:
            return "[\(value)]"
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
        case .dueDate, .startDate:
            let array: [DateGranulity] = [.day, .month, .year, .time]
            let dateFormatter = DateFormatter()
            for granulity in array {
                dateFormatter.dateFormat = granulity.format
                if dateFormatter.date(from: string) != nil {
                    return true
                }
            }
            return false
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
    
    var elements: Set<Token> = [.tag, .startDate, .dueDate]
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
        
        let shifting = globalBodyRange.location
        
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
            let foregroundColor = NSColor(calibratedRed: 73/255, green: 67/255, blue: 73/255, alpha: 1.0)
            backingStorage.addAttribute(.strikethroughStyle, value: 0, range: globalBodyRange)
            backingStorage.addAttribute(.foregroundColor, value: foregroundColor, range: globalBodyRange)
            
            if let enclosingRange = parseHashtag(in: body)?.enclosingRange.shifted(by: shifting) {
                backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
            }
            
            if let enclosingRange = parsePriority(in: body)?.enclosingRange.shifted(by: shifting) {
                backingStorage.addAttributes([.foregroundColor : NSColor.orange], range: enclosingRange)
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
        
        let priority = self.parsePriority(in: line)?.priority
        let dueDate = self.parseDueDate(in: line)?.date
        let startDate = self.parseStartDate(in: line)?.date
        let hashtag = self.hashtag(in: line)
        
        //let (_, enclosingRange) = parse(.type, inLine: line)!
        //let bodyRange = NSRange(location: enclosingRange.upperBound, length: line.count - enclosingRange.length)
        let body = line//line.substring(from: bodyRange).trimmingCharacters(in: .whitespaces)
   
        let task = Task(string: line, body: body, priority: priority!, hashtag: hashtag, dueDate: dueDate, startDate: startDate)
        
        return task
    }
    
    func isTask(_ body: String) -> Bool {
        return lineType(of: body) == .task
    }
    
    // ******** Parsing tokens ********
    
    // -------- common function --------
    
    func textCheckingResult(for pattern: String, in line: String) -> NSTextCheckingResult? {
        let range = NSString(string: line).range(of: line)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        return regex.firstMatch(in: line, options: [], range: range)
    }
    
    // -------- hashtag --------
    
    func hashtag(in line: String) -> String? {
        if let ( _, wordRange, _) = parseHashtag(in: line) {
            return line.substring(from: wordRange)
        }
        return nil
    }
    
    func parseHashtag(in line: String) -> (prefixRange: NSRange, wordRange: NSRange, enclosingRange: NSRange)? {
        let pattern = #"\B((#)(\w+))\B"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let prefixRange = match.range(at: 2)
            let wordRange = match.range(at: 3)
            let enclosingRange = match.range(at: 1)
            return (prefixRange, wordRange, enclosingRange)
        }
        return nil
    }
    
    func detectHashtag(in line: String, beginAt stringLocation: Int, forSelectionAt selectionLocation: Int) -> (element: Token, range: NSRange, enclosingRange: NSRange)? {
        let nSelLocation = selectionLocation - stringLocation
        if let (prefixRange, wordRange, enclosingRange) = parseHashtag(in: line) {
            if prefixRange.upperBound >= nSelLocation && wordRange.upperBound <= nSelLocation { 
                return (.tag, wordRange, enclosingRange)
            }
        }
        return nil
    }
    
    // -------- task priority --------
    
    func parsePriority(in line: String) -> (priority: TaskPriority, priorityRange: NSRange, enclosingRange: NSRange)? {
        if let (priorityRange, enclosingRange) = priorityRange(in: line) {
            let value = line.substring(from: priorityRange)
            switch value {
            case "x":
                return (.completed, priorityRange, enclosingRange)
            case " ":
                return (.uncompleted, priorityRange, enclosingRange)
            default:
                return (.hasPriority(value: value), priorityRange, enclosingRange)
            }
        }
        return nil
    }
    
    func priorityRange(in line: String) -> (priorityRange: NSRange, enclosingRange: NSRange)? {
        let pattern = #"^\t*(\[(x|\s|\-|[A-Z])\])\s"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let priorityRange = match.range(at: 2)
            let enclosingRange = match.range(at: 1)
             return (priorityRange, enclosingRange)
        }
        return nil
    }
    
    // -------- due date --------
    
    func parseDueDate(in line: String) -> (date: TaskDate, dateTimeRange: NSRange, enclosingRange: NSRange)? {
        let array: [DateGranulity] = [.day, .month, .year, .time]
        if let (dateTimeRange, enclosingRange) = dueDateRange(in: line) {
            let str = line.substring(from: dateTimeRange)
            let dateFormatter = DateFormatter()
            for granulity in array {
                dateFormatter.dateFormat = granulity.format
                if let date = dateFormatter.date(from: str) {
                    return (TaskDate(date: date, granulity: granulity), dateTimeRange, enclosingRange)
                }
            }
        }
        return nil
    }
    
    func dueDateRange(in line: String) -> (dateTimeRange: NSRange, enclosingRange: NSRange)? {
        let pattern = #"\B(@due\((.+?)\))\B"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let dateTimeRange = match.range(at: 2)
            let enclosingRange = match.range(at: 1)
             return (dateTimeRange, enclosingRange)
        }
        return nil
    }
    
    // -------- start date --------
    
    func parseStartDate(in line: String) -> (date: TaskDate, dateTimeRange: NSRange, enclosingRange: NSRange)? {
        let array: [DateGranulity] = [.day, .month, .year, .time]
        if let (dateTimeRange, enclosingRange) = startDateRange(in: line) {
            let str = line.substring(from: dateTimeRange)
            let dateFormatter = DateFormatter()
            for granulity in array {
                dateFormatter.dateFormat = granulity.format
                if let date = dateFormatter.date(from: str) {
                    return (TaskDate(date: date, granulity: granulity), dateTimeRange, enclosingRange)
                }
            }
            return nil
        }
        return nil
    }
    
    func startDateRange(in line: String) -> (dateTimeRange: NSRange, enclosingRange: NSRange)? {
        let pattern = #"\B(@start\((.+?)\))\B"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let dateTimeRange = match.range(at: 2)
            let enclosingRange = match.range(at: 1)
             return (dateTimeRange, enclosingRange)
        }
        return nil
    }
    
    
}







