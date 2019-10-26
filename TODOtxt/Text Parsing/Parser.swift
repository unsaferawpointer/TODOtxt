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
    
}



class Parser {
    
    var font: NSFont
    var boldFont: NSFont
    
    var textParagraphStyle: NSMutableParagraphStyle
    var taskParagraphStyle: NSMutableParagraphStyle
    var headerParagraphStyle: NSMutableParagraphStyle
    
    
    
    // ********** Init block **********
    init() {
        self.font = NSFont(name: "IBM Plex Mono", size: 14.0)!
        self.boldFont = NSFont(name: "IBM Plex Mono Medium", size: 14.0)!
        
        self.textParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        //self.textParagraphStyle.firstLineHeadIndent = 14.0
        //self.textParagraphStyle.headIndent = 14.0
        self.textParagraphStyle.paragraphSpacing = 4.0
        
        
        self.headerParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        self.headerParagraphStyle.alignment = .left
        //self.headerParagraphStyle.paragraphSpacing = 8.0
        
        self.taskParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        //self.taskParagraphStyle.firstLineHeadIndent = 14.0
        self.taskParagraphStyle.headIndent = 14.0
        self.taskParagraphStyle.paragraphSpacing = 4.0
        
        let block = NSTextBlock()
        //block.setBorderColor(NSColor.green)
        //block.setWidth(2.0, type: .absoluteValueType, for: .border)
        block.setWidth(14.0, type: .absoluteValueType, for: .padding)
        block.setContentWidth(100, type: .percentageValueType)
        
        //taskParagraphStyle.textBlocks = [block]
        
        
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
        
        // setup
        backingStorage.removeAttribute(.strikethroughStyle, range: globalBodyRange)
        
        switch lineType {
        case .empty:
            backingStorage.addAttribute(.font, value: font, range: globalBodyRange)
            backingStorage.addAttribute(.paragraphStyle, value: textParagraphStyle, range: globalBodyRange)
            return
        case .header:
            backingStorage.addAttribute(.font, value: boldFont, range: globalBodyRange)
            backingStorage.addAttribute(.foregroundColor, value: NSColor.headerTextColor, range: globalBodyRange)
            backingStorage.addAttribute(.paragraphStyle, value: headerParagraphStyle, range: globalBodyRange)
            return
        case .task:
            backingStorage.addAttribute(.font, value: font, range: globalBodyRange)
            backingStorage.addAttribute(.paragraphStyle, value: taskParagraphStyle, range: globalBodyRange)
            break
        case .text:
            
            backingStorage.addAttribute(.font, value: font, range: globalBodyRange)
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalBodyRange)
            backingStorage.addAttribute(.paragraphStyle, value: textParagraphStyle, range: globalBodyRange)
            return
        }
        
        
        guard let (status, statusPrefixRange, statusRange, enclosingPriorityRange) = parseStatus(in: body) else { fatalError("Task has no priority. Invalid line type")}
        
        backingStorage.addAttribute(.link, value: 1, range: statusRange.shifted(by: shifting))
        
        switch status {
        case .completed:
            backingStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: globalBodyRange)
            backingStorage.addAttribute(.strikethroughStyle, value: 1, range: globalBodyRange)
            backingStorage.addAttribute(.prefix, value: 3, range: statusRange.shifted(by: shifting))
        case .uncompleted:
            
            //backingStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: globalBodyRange)
            backingStorage.addAttributes([.foregroundColor : NSColor.orange], range: enclosingPriorityRange.shifted(by: shifting))
            backingStorage.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: statusPrefixRange.shifted(by: shifting))
            
            if let enclosingRange = parseHashtag(in: body)?.enclosingRange.shifted(by: shifting) {
                backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
            }
            
            if let enclosingRange = parseDueDate(in: body)?.enclosingRange.shifted(by: shifting) {
                backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
            }
            
            if let enclosingRange = parseStartDate(in: body)?.enclosingRange.shifted(by: shifting) {
                backingStorage.addAttributes([.foregroundColor : NSColor.secondaryLabelColor], range: enclosingRange)
            }
            
        }
        
    }
    
    func parseGroups(backingStorage: NSMutableAttributedString, extendedRange: NSRange) {
        //backingStorage.removeAttribute(.foregroundColor, range: backingStorage.mutableString.fullRange)
        let mutStr = backingStorage.mutableString
        print("ext = \(extendedRange)")
        if extendedRange.location > 0 {
            let firstLine = mutStr.lineRange(for: NSRange(location: extendedRange.location - 5, length: 0))
            print("firstLine = \(firstLine)")
            backingStorage.addAttribute(.backgroundColor, value: NSColor.green, range: firstLine)
        }
        
        
        /*
        backingStorage.mutableString.enumerateSubstrings(in: extendedRange, options: .byLines) { (substring, range, enclosingRange, stop) in
            i += 1
            let color = i%2 == 0 ? NSColor.gray : NSColor.lightGray
            backingStorage.addAttribute(.backgroundColor, value: NSColor.green, range: enclosingRange)
            backingStorage.addAttribute(.backgroundColor, value: color, range: range)
        }
        */
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
        
        if parseStatus(in: body) != nil {
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
    
    /// Parse string to [Task], where task.tasks.isEmpty == true
    func parse(_ mutString: NSMutableString, in editedRange: NSRange) -> [Task] {
        
        var array = [Task]()
        mutString.enumerateSubstrings(in: editedRange, options: .byLines) { (substring, substringRange, enclosingRange, stop) in
            if let body = substring, let task = self.parseTask(for: body) {
                array.append(task)
            }
        }
        
        return array
    }
    
    func parseTasksTree(_ mutString: NSMutableString, in editedRange: NSRange) -> [Task] {
        
        var array = [Task]()
        var createNew = true
        mutString.enumerateSubstrings(in: editedRange, options: .byLines) { (substring, substringRange, enclosingRange, stop) in
            if let body = substring, let task = self.parseTask(for: body)  {
                let indent = task.indent
                
                if !array.isEmpty {
                    
                    if array.last!.indent < task.indent && !createNew {
                        array.last?.tasks.append(task)
                        createNew = false
                    } else {
                        array.append(task)
                        createNew = false
                    }
                } else {
                    array.append(task)
                }
            } else {
                createNew = true
            }
        }
        
        return array
    }
    
    // WARNING ambiguous func name
    // parsing todo
    func parseTask(for line: String) -> Task? {
        
        let type = lineType(of: line)
        
        guard type == .task else { return nil }
        
        let (status, _, _, statusEnclosingRange) = self.parseStatus(in: line)!
        let indent = statusEnclosingRange.location
        
        let dueDate: TaskDate? = self.parseDueDate(in: line)?.date
        let startDate: TaskDate? = self.parseStartDate(in: line)?.date
        let hashtag: String? = self.parseHashtag(in: line)?.hashtag
        
        let mutBodyStr = NSMutableString(string: line)
        if let enclosingRange = self.statusRange(in: mutBodyStr.string)?.enclosingRange {
            mutBodyStr.replaceCharacters(in: enclosingRange, with: " ")
        }
        if let enclosingRange = self.dueDateRange(in: mutBodyStr.string)?.enclosingRange {
            mutBodyStr.replaceCharacters(in: enclosingRange, with: " ")
        }
        if let enclosingRange = self.startDateRange(in: mutBodyStr.string)?.enclosingRange {
            mutBodyStr.replaceCharacters(in: enclosingRange, with: " ")
        }
        if let enclosingRange = self.hashtagRange(in: mutBodyStr.string)?.enclosingRange {
            mutBodyStr.replaceCharacters(in: enclosingRange, with: " ")
        }
       
        let body = mutBodyStr.string.trimmingCharacters(in: .whitespaces)
   
        let task = Task(string: line, body: body, priority: status, hashtag: hashtag, dueDate: dueDate, startDate: startDate, indent: indent)
        
        return task
    }
    
    func isTask(_ body: String) -> Bool {
        return lineType(of: body) == .task
    }
    
    // ******** Parsing tokens ********
    
    // -------- common function --------
    
    func textCheckingResult(for pattern: String, in line: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return nil }
        return regex.firstMatch(in: line, options: [], range: line.fullRange)
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
    
    func detectHashtag(in line: String, beginAt stringLocation: Int, forSelectionAt selectionLocation: Int) -> (element: Token, range: NSRange, enclosingRange: NSRange)? {
        let nSelLocation = selectionLocation - stringLocation
        if let (prefixRange, wordRange, enclosingRange) = hashtagRange(in: line) {
            if prefixRange.upperBound >= nSelLocation && wordRange.upperBound <= nSelLocation { 
                return (.tag, wordRange, enclosingRange)
            }
        }
        return nil
    }
    
    // -------- task priority --------
    
    func parseStatus(in line: String) -> (status: TaskStatus, prefixRange: NSRange, valueRange: NSRange, enclosingRange: NSRange)? {
        if let (prefixRange, priorityRange, enclosingRange) = statusRange(in: line) {
            let value = line.substring(from: priorityRange)
            switch value {
            case "x":
                return (.completed, prefixRange, priorityRange, enclosingRange)
            default:
                return (.uncompleted, prefixRange, priorityRange, enclosingRange)
            }
        }
        return nil
    }
    
    func statusRange(in line: String) -> (prefixRange: NSRange, statusRange: NSRange, enclosingRange: NSRange)? {
        
        let pattern = #"^(\t*)((x|\*|-|>))\s"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let statusRange = match.range(at: 3)
            let enclosingRange = match.range(at: 2)
            let prefixRange = match.range(at: 1)
            return (prefixRange, statusRange, enclosingRange)
        }
        return nil
    }
    
    // -------- due date --------
    
    func parseDueDate(in line: String) -> (date: TaskDate, dateTimeRange: NSRange, enclosingRange: NSRange)? {
        
        let array: [DateGranulity] = [.day, .month, .year, .time]
        if let (dateTimeRange, enclosingRange) = dueDateRange(in: line) {
            let str = line.substring(from: dateTimeRange)
            print("dueDte = \(str)")
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
        let pattern = #"(\s?@due\((.+?)\)\s?)"#
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
        }
        return nil
    }
    
    func startDateRange(in line: String) -> (dateTimeRange: NSRange, enclosingRange: NSRange)? {
        let pattern = #"\s(@start\((.+?)\))\s"#
        if let match = textCheckingResult(for: pattern, in: line) {
            let dateTimeRange = match.range(at: 2)
            let enclosingRange = match.range(at: 1)
             return (dateTimeRange, enclosingRange)
        }
        return nil
    }
    
    
}







