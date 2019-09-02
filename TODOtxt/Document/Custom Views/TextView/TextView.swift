//
//  TextView.swift
//  TODO txt
//
//  Created by subzero on 26/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol AutoCompletionDelegate {
    func complete(element: Element) -> [String]
}

extension String {
    static var upArrow: String {
        return String(Character(UnicodeScalar(NSUpArrowFunctionKey)!))
    }
    
    static var downArrow: String {
        return String(Character(UnicodeScalar(NSDownArrowFunctionKey)!))
    }
    
    static var leftArrow: String {
        return String(Character(UnicodeScalar(NSLeftArrowFunctionKey)!))
    }
    
    static var rightArrow: String {
        return String(Character(UnicodeScalar(NSRightArrowFunctionKey)!))
    }
    
    static var backspace: String {
        return String(Character(UnicodeScalar(NSBackspaceCharacter)!))
    }
} 

struct PriorityArray {
    let array: [String] = ["A","B","C","D","E","F","G","H","I","K","L","M","N","O","P","Q","R","S","T","V","X", "Y","Z"]
    
    func element(before otherElement: String) -> String {
        if let index = array.firstIndex(of: otherElement), index > 0 {
            return array[index - 1]
        }
        return otherElement
    }
    
    func element(after otherElement: String) -> String {
        if let index = array.firstIndex(of: otherElement), index < array.count - 1 {
            return array[index + 1]
        }
        return otherElement
    }
    
    var first: String {
        return array.first!
    }
    
    var last: String {
        return array.last!
    }
}

class TextView: NSTextView {
    
    weak var rulerView: RulerView?
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
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
    
    var completionDelegate: AutoCompletionDelegate?
    var currentPopover: AutocompletionPopover?
    
    func reload(with text: String) {
        undoManager?.removeAllActions()
        currentPopover?.close()
        let textStorage = self.textStorage as! TextStorage
        textStorage.observeChanging = false
        self.string = text
        textStorage.observeChanging = true
    }
    
    
    
    override func keyDown(with event: NSEvent) {
        
        var shouldComplete = true
        
        print("keyCode pressed = \(event.keyCode)")
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
    
    // ********** Context menu **********
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(changeLayoutOrientation(_:)) {
            return false
        }
        return super.validateUserInterfaceItem(item)
    }
    
    // ========
    // MENU SELECTORS
    // ========
    
    private func validateSelection() -> Bool {
        guard let lineString = selectedLineString else { return false}
        return parser.hasTodo(lineString)
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        print("validateMenuItem")
        
        if menuItem.action == #selector(removeLines(_:)) {
            return validateSelection()
        } else if menuItem.action == #selector(encreasePriority(_:)) {
            return validateSelection()
        } else if menuItem.action == #selector(decreasePriority(_:)) {
            return validateSelection()
        } else if menuItem.action == #selector(toggleCompletion(_:)) {
            return validateSelection()
        }
        return super.validateMenuItem(menuItem)
    }
    
    
    // ********** Selectors **********
    // ---------- common ----------
    @IBAction func toggleCompletion(_ sender: Any?) {
        
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
        
        if let (_ , enclosingRange) = parser.parse(.status, inLine: lineString, at: lineRange.location) {
            replaceText(in: enclosingRange, with: "")
        } else {
            let leadLineRange = NSRange(location: lineRange.location, length: 0)
            replaceText(in: leadLineRange, with: "x ")
        }
        
    }
    
    @IBAction func removeLines(_ sender: Any?) {
        replaceText(in: selectedLines, with: "")
    }
    
    // ---------- priority ----------
    
    @IBAction func encreasePriority(_ sender: Any?) {
        
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
        
        let priorityArray = PriorityArray()
        
        if let (range , enclosingRange) = parser.parse(.priority, inLine: lineString, at: lineRange.location) {
            let oldPriority = mutString.substring(with: range)
            let newPriority = priorityArray.element(before: oldPriority)
            replaceText(in: enclosingRange, with: Element.priority.prefixString(for: newPriority))
        } else {
            let newPriority = priorityArray.last
            if let (_ , enclosingRange) = parser.parse(.status, inLine: lineString, at: lineRange.location) {
                let leadingRange = NSRange(location: enclosingRange.upperBound, length: 0)
                replaceText(in: leadingRange, with: Element.priority.prefixString(for: newPriority))
            } else {
                let leadLineRange = NSRange(location: lineRange.location, length: 0)
                replaceText(in: leadLineRange, with: Element.priority.prefixString(for: newPriority))
            }
        }
        
    }
    
    @IBAction func decreasePriority(_ sender: Any?) {
        
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
        
        let priorityArray = PriorityArray()
        
        if let (range , enclosingRange) = parser.parse(.priority, inLine: lineString, at: lineRange.location) {
            let oldPriority = mutString.substring(with: range)
            let newPriority = priorityArray.element(after: oldPriority)
            replaceText(in: enclosingRange, with: Element.priority.prefixString(for: newPriority))
        } else {
            let newPriority = priorityArray.first
            if let (_ , enclosingRange) = parser.parse(.status, inLine: lineString, at: lineRange.location) {
                let leadingRange = NSRange(location: enclosingRange.upperBound, length: 0)
                replaceText(in: leadingRange, with: Element.priority.prefixString(for: newPriority))
            } else {
                let leadLineRange = NSRange(location: lineRange.location, length: 0)
                replaceText(in: leadLineRange, with: Element.priority.prefixString(for: newPriority))
            }
        }
        
    }
    
    @IBAction func removePriority(_ sender: Any?) {
        
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
       
        if let (_ , enclosingRange) = parser.parse(.priority, inLine: lineString, at: lineRange.location) {
            replaceText(in: enclosingRange, with: "")
        } 
        
    }
    
    // ---------- date ----------
    
    @IBAction func setDueDate(_ sender: Any?) {
        
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
        
        var date = Date()
        let element: Element = .date(granulity: .day)
        
        var popoverAnchor: NSRange!
        
        if let (range, enclosingRange) = parser.parse(element, inLine: lineString, at: lineRange.location){
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
    }
    
    @IBAction func encreaseDueDate(_ sender: Any?) {
        changeDueDate(by: 1)
    }
    
    @IBAction func decreaseDueDate(_ sender: Any?) {
        changeDueDate(by: -1)
    }
    
    private func changeDueDate(by day: Int) {
        
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
        
        let element: Element = .date(granulity: .day)
        
        if let (range, enclosingRange) = parser.parse(element, inLine: lineString, at: lineRange.location){
            let mention = textStorage!.mutableString.substring(with: range)
            let oldDate = DateGranulity.day.date(from: mention)!
            let newDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: day, to: oldDate)!
            let newStr = DateGranulity.day.string(from: newDate)!
            replaceText(in: enclosingRange, with: element.prefixString(for: newStr))
        }
        
    }
    
    @IBAction func removeDate(_ sender: Any?) {
        guard let lineRange = selectedLine, let lineString = selectedLineString else { return }
        if let (_ , enclosingRange) = parser.parse(.date(granulity: .day), inLine: lineString, at: lineRange.location) {
            replaceText(in: enclosingRange, with: "")
        } 
    }
    
    override func viewDidChangeEffectiveAppearance() {
        if #available(OSX 10.14, *) {
            super.viewDidChangeEffectiveAppearance()
        } else {
            // Fallback on earlier versions
        }
        print(#function)
    }
    
    func invalidateColorScheme() {
        self.selectedTextAttributes = [.backgroundColor : theme.selection, .foregroundColor : theme.foreground]
    }
    
}

extension TextView {
    
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
        currentPopover?.close()
    }
    
    private func replaceText(in range: NSRange, with string: String) {
        if (shouldChangeText(in: range, replacementString: string)) {
            textStorage!.mutableString.replaceCharacters(in: range, with: string)
            didChangeText()
            let newRange = NSRange(location: range.location, length: string.count)
            showFindIndicator(for: newRange)
        }
    }
    
    
}

// ********** Completion **********

extension TextView: AutocompletionPopoverDelegate {
    
    func autocompletionDidChange(_ sender: AutocompletionPopover, str: String, element: Element) {
        print(#function)
        guard editedRange != nil else { return }
        replaceText(in: editedRange!, with: element.prefixString(for: str))
        self.editedRange = nil
        sender.close()
    }
    
    private func findCompletion(in sRange: NSRange) -> (element: Element, range: NSRange, enclosingRange: NSRange)? {
        
        let lineRange = textStorage!.mutableString.lineRange(for: sRange)
        guard lineRange.length > 0 else { return nil }
        
        let body = textStorage!.mutableString.substring(with: lineRange)
        
        let result = parser.detectFirst(elements: [.project, .context, .date(granulity: .day), .date(granulity: .month), .date(granulity: .year)], in: body, beginAt: lineRange.location, forSelectionAt: sRange.location)
        
        return result
    }
    
    private func performAutocompletion () {
        
        let sRange = self.selectedRange()
        guard sRange.length == 0 else { return }
        
        if let (element, range, enclosingRange) = findCompletion(in: sRange) {
            print("range = \(range)")
            print("enclosingRange = \(enclosingRange)")
            let mention = textStorage!.mutableString.substring(with: range)
            self.editedRange = enclosingRange
            switch element {
            case .context, .project:
                var data = completionDelegate!.complete(element: element)
                data.removeAll { (value) -> Bool in
                    return value == mention || !value.hasPrefix(mention)
                }
                guard data.count > 0 else { return }
                
                let popover = TablePopover()
                popover.reload(data, with: mention)
                popover.element = element
                show(popover, at: range.location)
            case .date(let granulity) where granulity == .month || granulity == .year:
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = granulity.format
                let date = dateFormatter.date(from: mention)!
                
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



extension TextView {
    override func updateRuler() {
        super.updateRuler()
        rulerView?.needsDisplay = true
    }
    
}


