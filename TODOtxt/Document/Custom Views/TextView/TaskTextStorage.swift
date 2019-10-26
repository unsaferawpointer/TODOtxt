//
//  TextStorage.swift
//  TODO txt
//
//  Created by subzero on 03/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol TaskTextStorageDelegate: class {
    func taskTextStorage(insert tasks: [Task])
    func taskTextStorage(remove tasks: [Task])
}

class TaskTextStorage: NSTextStorage {
    
    let backingStore = NSTextStorage()
    
    weak var taskDelegate: TaskTextStorageDelegate?
    var parser: Parser = Parser()
    
    var hasChanged = false
    
    var observeChanging = true
    
    override var string: String {
        return backingStore.string
    }
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return backingStore.attributes(at: location, effectiveRange: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        
        let nsstring = NSString(string: str)
        let delta = nsstring.length - range.length
        hasChanged = true
        beginEditing()
        if observeChanging { toRemove(editedRange: range, with: delta) }
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: delta)
        if observeChanging { toInsert(editedRange: range, with: delta) }
        endEditing()
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    override func processEditing() {
        print(#function)
        
        
        if hasChanged {
            highlight(in: editedRange)
        }
        hasChanged = false
        super.processEditing()
    }
    
}

// ********** Parsing data **********

extension TaskTextStorage {
    
    private func toRemove(editedRange: NSRange, with delta: Int) {
        
        let firstLineRange = backingStore.mutableString.lineRange(for: editedRange)
        let maxRange = NSRange(location: editedRange.location + editedRange.length, length: 0)
        let lastLineRange = backingStore.mutableString.lineRange(for: maxRange)
        let fullRange = NSUnionRange(firstLineRange, lastLineRange)
        
        let tasks = parser.parse(backingStore.mutableString, in: fullRange)
        self.taskDelegate?.taskTextStorage(remove: tasks)
    }
    
    private func toInsert(editedRange: NSRange, with delta: Int) {
        
        let newEditedRange = NSRange(location: editedRange.location, length: editedRange.length + delta)
        let firstLineRange = backingStore.mutableString.lineRange(for: newEditedRange)
        let extendedRange = NSRange(location: editedRange.location + editedRange.length + delta, length: 0)
        let lastLineRange = backingStore.mutableString.lineRange(for: extendedRange)
        let fullRange = NSUnionRange(firstLineRange, lastLineRange)
        
        let tasks = parser.parse(backingStore.mutableString, in: fullRange)
        self.taskDelegate?.taskTextStorage(insert: tasks)
    }
    
}

// ********** Hightlighting **********

extension TaskTextStorage {
    
    func highlight(in range: NSRange) {
        
        let firstLineRange = backingStore.mutableString.lineRange(for: range)
        let extendedRange = NSRange(location: range.location + range.length, length: 0)
        let lastLineRange = backingStore.mutableString.lineRange(for: extendedRange)
        let fullRange = NSUnionRange(firstLineRange, lastLineRange)
        
        //parser.highlight(theme: theme, backingStorage: backingStore, in: fullRange)
        parser.parseGroups(backingStorage: backingStore, extendedRange: fullRange)
    }
    
}

