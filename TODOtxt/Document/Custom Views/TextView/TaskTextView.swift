//
//  TextView.swift
//  TODO txt
//
//  Created by subzero on 26/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol TaskTextViewDelegate: class {
    func taskTextView(for element: Token) -> [String]
}

class TaskTextView: NSTextView {
    
    weak var rulerView: TaskRulerView?
    weak var autocompletionDelegate: TaskTextViewDelegate?
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
    // ********** Working with text **********
    
    var mutString: NSMutableString {
        return textStorage!.mutableString
    }
    
    var selectedLine: NSRange? {
        let sRange = selectedRange()
        return mutString.singleLine(for: sRange)
    }
    
    var selectedLineString: String? {
        if let line = selectedLine {
            return mutString.substring(with: line)
        }
        return nil
    }
    
    var selectedLines: NSRange {
        let sRange = self.selectedRange()
        return mutString.lineRange(for: sRange)
    }
    
    var fullRange: NSRange {
        return textStorage!.mutableString.fullRange
    }
    
    var editedRange: NSRange?
    var parser: Parser = Parser()
    
    var taskTextStorage: TaskTextStorage {
        return textStorage as! TaskTextStorage
    }
    
    // ********** Popovers **********
    
    var currentPopover: AutocompletionPopover?
    
    // ******** Key event handling ********
    
    override func keyDown(with event: NSEvent) {
        
        var shouldComplete = true
        
        //print("keyCode pressed = \(event.keyCode)")
        switch event.keyCode {
        case 51:
            // delete
            if currentPopover?.isShown ?? false {
                currentPopover?.close()
            }
            
            shouldComplete = false
        case 53:
            // esc
            currentPopover?.close()
            return
        case 125:
            // down
            if let popover = currentPopover , popover.isShown {
                popover.moveDown()
                return 
            } 
        case 126:
            // up
            if let popover = currentPopover, popover.isShown {
                popover.moveUp()
                return 
            }
        case 123:
            // left
            if let popover = currentPopover as? DatePopover, popover.isShown {
                popover.moveLeft()
                return 
            }
        case 124:
            // right
            if let popover = currentPopover as? DatePopover, popover.isShown {
                popover.moveRight()
                return 
            }
        case 36:
            // return
            if let popover = currentPopover, popover.isShown {
                popover.complete()
                return
            }
        case 48:
            // tab
            if let popover = currentPopover, popover.isShown {
                popover.complete()
                return
            }
        case 49:
            // space
            currentPopover?.close()
        default:
            if let popover = currentPopover as? DatePopover, popover.isShown {
                popover.close()
            }
            break
        }
        
        super.keyDown(with: event)
        if shouldComplete {
            performAutocompletion()
        }
        
    }
    
    override func deleteBackward(_ sender: Any?) {
        let selRange = selectedRange()
        let location = selRange.location
        let startRange = NSRange(location: location, length: 0)
        
        let lineRange = mutString.lineRange(for: startRange)
        //print("selRange = \(selRange)")
        //print("lineRange = \(lineRange)")
        let pattern = #"^\t*(\[(x|\s|\-|[A-Z])\]\s).*"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let lineStr = string.substring(from: lineRange)
        //print("firstTask = \(lineStr)")
        if let result = regex.firstMatch(in: string, options: [], range: lineRange), result.range(at: 1).upperBound == selRange.location && selRange.length == 0 {
            replaceText(in: result.range(at: 1), with: "")
        } else {
            super.deleteBackward(sender)
        }
    }
    
    override func insertNewline(_ sender: Any?) {
        
        let selRange = selectedRange()
        let location = selRange.location
        let startRange = NSRange(location: location, length: 0)
        
        let lineRange = mutString.lineRange(for: startRange)
        //print("selRange = \(selRange)")
        //print("lineRange = \(lineRange)")
        if selRange.length == 0 {
            
            let pattern = #"^(\t*((x|\*|-)\s)).*"#
            let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
            //print("firstTask = \(lineStr)")
            if let result = regex.firstMatch(in: string, options: [], range: lineRange), result.range(at: 2).upperBound <= location {
                //print("location = \(location)")
                let indent = result.range(at: 2).location - lineRange.location
                //print("upperRange = \(result.range(at:1).upperBound)")
                if result.range(at: 2).upperBound == location {
                    replaceCharacters(in: result.range(at:1), with: "")
                    
                } else {
                    let array = Array<String>.init(repeating: "\t", count: indent)
                    replaceCharacters(in: NSRange(location: selRange.upperBound, length: 0), with: "\n\(array.joined())- ")
                }
            } else {
                super.insertNewline(sender)
            }
        } else {
            super.insertNewline(sender)
        }
        
    }
    
    override func insertTab(_ sender: Any?) {
        let selRange = selectedRange()
        let location = selRange.location
        let startRange = NSRange(location: location, length: 0)
        
        let lineRange = mutString.lineRange(for: startRange)
        //print("selRange = \(selRange)")
        //print("lineRange = \(lineRange)")
        if selRange.length == 0 {
            
            let pattern = #"^(\t*((x|\*|-)\s)).*"#
            let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
            let lineStr = string.substring(from: lineRange)
            //print("firstTask = \(lineStr)")
            if let result = regex.firstMatch(in: string, options: [], range: lineRange), result.range(at: 2).upperBound <= location {
                //print("location = \(location)")
                //print("upperRange = \(result.range(at:1).upperBound)")
                if result.range(at: 2).upperBound == location {
                    replaceCharacters(in: NSRange(location: result.range(at: 1).location, length: 0), with: "\t")
                    
                } else {
                    let range = NSRange(location: lineRange.location, length: 0)
                    replaceText(in: range, with: "\t")
                }
            } else {
                super.insertTab(sender)
            }
        } else {
            super.insertTab(sender)
        }
    }
    
    // ********** Context menu **********
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(changeLayoutOrientation(_:)) {
            return false
        }
        return super.validateUserInterfaceItem(item)
    }
    
    // ********* Menu selectors *********
    
    private func isSingleTaskSelection() -> Bool {
        guard let lineString = selectedLineString else { return false }
        return parser.isTask(lineString)
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        if menuItem.action == #selector(toggleCompletion(_:)) {
            return isSingleTaskSelection()
        } else if menuItem.action == #selector(removeLines(_:)) {
            return isSingleTaskSelection()
        } else if menuItem.action == #selector(removePriority(_:)) {
            return isSingleTaskSelection()
        } else if menuItem.action == #selector(setDueDate(_:)) {
            return isSingleTaskSelection()
        } else if menuItem.action == #selector(encreaseDueDate(_:)) {
            return isSingleTaskSelection()
        } else if menuItem.action == #selector(decreaseDueDate(_:)) {
            return isSingleTaskSelection()
        } else if menuItem.action == #selector(removeDueDate(_:)) {
            return isSingleTaskSelection()
        }
        
        return super.validateMenuItem(menuItem)
    }
    
    
    // ********** Selectors **********
    
    @IBAction func shiftRight(_ sender: Any?) {
        guard let lineRange = selectedLine else { return }
        let line = mutString.substring(with: lineRange)
        
        if parser.lineType(of: line) == .task {
            let range = NSRange(location: lineRange.location, length: 0)
            replaceText(in: range, with: "\t")
        }
    }
    
    
    @IBAction func shiftLeft(_ sender: Any?) {
        guard let lineRange = selectedLine else { return }
        let line = mutString.substring(with: lineRange)
        
        if parser.lineType(of: line) == .task, line.hasPrefix("\t") {
            let range = NSRange(location: lineRange.location, length: 1)
            replaceText(in: range, with: "")
        }
    }
    
    
    // ---------- common ----------
    @IBAction func toggleCompletion(_ sender: Any?) {
        
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
        
        guard let (oldPriority, _, priorityRange, enclosingRange) = parser.parseStatus(in: lineString) else { return }
        
        let newPriority = (oldPriority == .completed) ? "-" : "x"
        replaceText(in: enclosingRange.shifted(by: lineRange.location), with: "\(newPriority)")
        
    }
    
    @IBAction func removeLines(_ sender: Any?) {
        replaceText(in: selectedLines, with: "")
    }
    
    
    @IBAction func removePriority(_ sender: Any?) {
        
        guard let lineString = selectedLineString else { return }
        
        if let (_, _, _ , enclosingRange) = parser.parseStatus(in: lineString) {
            replaceText(in: enclosingRange, with: "[ ]")
        }
        
    }
    
    // ---------- date ----------
    
    @IBAction func setDueDate(_ sender: Any?) {
        
        /*
        guard let lineString = selectedLineString else { return }
        
        var date = Date()
        let element: Token = .dueDate
        
        var popoverAnchor: NSRange!
        
        if let (oldDate, range, enclosingRange) = parser.parseDueDate(in: lineString){
            date = oldDate.date
            self.editedRange = enclosingRange
            popoverAnchor = range
        } else {
            if let (editedRange, lastSymbolRange) = parser.tailLine(substring: lineString, with: lineRange.location) {
                self.editedRange = editedRange
                popoverAnchor = NSRange(location: lastSymbolRange.location, length: 1)
            } else {
                fatalError("range not found")
            }
        }
        
        if let (range, enclosingRange) = parser.parse(element, inLine: lineString, with: lineRange.location){
            let mention = textStorage!.mutableString.substring(with: range)
            date = DateGranulity.day.date(from: mention)!
            self.editedRange = enclosingRange
            popoverAnchor = range
        } else {
            if let (editedRange, lastSymbolRange) = parser.tailLine(substring: lineString, with: lineRange.location) {
                self.editedRange = editedRange
                popoverAnchor = NSRange(location: lastSymbolRange.location, length: 1)
            } else {
                fatalError("range not found")
            }
        }
        
        let popover = DatePopover()
        popover.setDate(date)
        show(popover, in: popoverAnchor)
 */
    }
    
    @IBAction func encreaseDueDate(_ sender: Any?) {
        changeDueDate(by: 1)
    }
    
    @IBAction func decreaseDueDate(_ sender: Any?) {
        changeDueDate(by: -1)
    }
    
    private func changeDueDate(by day: Int) {
        
        guard let lineString = selectedLineString else { return }
        
        if let (oldDate, dateTimeRange, enclosingRange) = parser.parseDueDate(in: lineString) {
            let newDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: day, to: oldDate.date)!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = oldDate.granulity.format
            let newDateStr = dateFormatter.string(from: newDate)
            replaceText(in: enclosingRange, with: Token.dueDate.prefixString(for: newDateStr))
        }
        
    }
    
    @IBAction func removeDueDate(_ sender: Any?) {
        guard let lineString = selectedLineString else { return }
        if let (_ , enclosingRange) = parser.dueDateRange(in: lineString) {
            replaceText(in: enclosingRange, with: "")
        } 
    }
    
    func removeCompleted() {
        /*
        textStorage?.mutableString.enumerateSubstrings(in: fullRange, options: .byLines, using: { (substring, range, enclosing, stop) in
            if let body = substring, self.parser.parse(.type, inLine: body) != nil {
                print("substring = \(substring)")
                print("range = \(range)")
                print("enclosing = \(enclosing)")
                self.textStorage?.replaceCharacters(in: enclosing, with: "")
            }
        })*/
    }
    
    func invalidateColorScheme() {
        self.selectedTextAttributes = [.backgroundColor : theme.selection]
    }
    
}

extension TaskTextView {
    
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
        currentPopover?.close()
    }
    
    @objc func replaceText(in range: NSRange, with string: String) {
        //print(#function)
        guard shouldChangeText(in: range, replacementString: string) else { return }
        //print("oldRange = \(range) newString = \(string)")
        let newRange = NSRange(location: range.location, length: string.count)
        let oldString = textStorage!.mutableString.substring(with: range)
        //print("newRange = \(newRange) oldString = \(oldString)")
        if let u = undoManager {
          u.registerUndo(withTarget: self) { this in
            this.unreplaceText(in: newRange, with: oldString)
          }//end u
          u.setActionName("unreplaceText")
        }//end if
        
        
        replaceCharacters(in: range, with: string)
        
        
        showFindIndicator(for: newRange)
    }
    
    @objc func unreplaceText(in range: NSRange, with string: String) {
        
        guard shouldChangeText(in: range, replacementString: string) else { return }
        
        let newRange = NSRange(location: range.location, length: string.count)
        let oldString = textStorage!.mutableString.substring(with: range)
        
        if let u = undoManager {
          u.registerUndo(withTarget: self) { this in
            this.replaceText(in: newRange, with: oldString)
          }//end u
          u.setActionName("replaceText")
        }//end if
        
        replaceCharacters(in: range, with: string)
        
        showFindIndicator(for: newRange)
    }
    
    
    
}

// ********** Completion **********

extension TaskTextView: AutocompletionPopoverDelegate {
    
    func autocompletionDidChange(_ sender: AutocompletionPopover, str: String, element: Token) {
        print(#function)
        guard editedRange != nil else { return }
        replaceText(in: editedRange!, with: element.prefixString(for: str))
        self.editedRange = nil
        sender.close()
    }
    
    private func findCompletion(in sRange: NSRange) -> (element: Token, range: NSRange, enclosingRange: NSRange)? {
        
        let lineRange = textStorage!.mutableString.lineRange(for: sRange)
        guard lineRange.length > 0 else { return nil }
        
        let body = textStorage!.mutableString.substring(with: lineRange)
        
        let result = parser.detectHashtag(in: body, beginAt: lineRange.location, forSelectionAt: sRange.location)
        
        return result
    }
    
    private func performAutocompletion () {
        
        let sRange = self.selectedRange()
        guard sRange.length == 0 else { return }
        
        if let (element, range, enclosingRange) = findCompletion(in: sRange) {
            
            let mention = textStorage!.mutableString.substring(with: range)
            self.editedRange = enclosingRange
            switch element {
            case .tag:
                
                var data: [String] = autocompletionDelegate?.taskTextView(for: element) ?? []
                
                data.removeAll { (value) -> Bool in
                    return value == mention || !value.hasPrefix(mention)
                }
                guard data.count > 0 else { return }
                
                let popover = TablePopover()
                popover.reload(data, with: mention)
                popover.element = element
                show(popover, at: range.location)
            case .dueDate:
                
                var date: Date!
                
                let array: [DateGranulity] = [.day, .month, .year, .time]
                let dateFormatter = DateFormatter()
                for granulity in array {
                    dateFormatter.dateFormat = granulity.format
                    if let d = dateFormatter.date(from: string) {
                        date = d
                    }
                }
                
                let popover = DatePopover()
                popover.setDate(date)
                show(popover, at: range.location)
            default:
                break
            }
        }
    }
    
    private func show(_ popover: AutocompletionPopover, in range: NSRange) {
        self.currentPopover?.close()
        self.currentPopover = popover
        let glyphRange = layoutManager!.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let rect = layoutManager!.boundingRect(forGlyphRange: glyphRange, in: textContainer!)
        if !popover.isShown {
            popover.show(relativeTo: rect, of: self, preferredEdge: NSRectEdge.maxY)
            popover.autocompletionDelegate = self
        } 
        
    }
    
    private func show(_ popover: AutocompletionPopover, at characterIndex: Int) {
        self.currentPopover?.close()
        self.currentPopover = popover
        let range = NSRange(location: characterIndex, length: 1)
        let glyphRange = layoutManager!.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let rect = layoutManager!.boundingRect(forGlyphRange: glyphRange, in: textContainer!)
        if !popover.isShown {
            popover.show(relativeTo: rect, of: self, preferredEdge: NSRectEdge.maxY)
            popover.autocompletionDelegate = self
        } 
        
    }
    
}

extension TaskTextView {
    
    override func updateRuler() {
        super.updateRuler()
        //print(#function)
        rulerView?.needsDisplay = true
    }
    
    // -------- Set w/o text parsing. Only highlight text --------
    
    func set(text: String) {
        undoManager?.removeAllActions()
        currentPopover?.close()
        taskTextStorage.observeChanging = false
        self.string = text
        taskTextStorage.observeChanging = true
    }
    
}


