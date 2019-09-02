//
//  TextStorage.swift
//  TODO txt
//
//  Created by subzero on 03/09/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol TextStorageDataDelegate: class {
    func dataDidChanged(toInsert: [ToDo], toDelete: [ToDo])
}

class TextStorage: NSTextStorage {
    
    weak var dataDelegate: TextStorageDataDelegate?
    
    let backingStore = NSTextStorage()
    var parser: Parser = Parser()
    
    var inserted = [ToDo]()
    var removed = [ToDo]()
    var observeChanging = true
    
    var timer: Timer!
    
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
        
        highlight()
        
        if !removed.isEmpty || !inserted.isEmpty {
            dataDelegate?.dataDidChanged(toInsert: inserted, toDelete: removed)
            removed.removeAll()
            inserted.removeAll()
        }
        
        super.processEditing()
    }
    
}

// ===================
// PARSING DATA
// ===================
extension TextStorage {
    
    private func toRemove(editedRange: NSRange, with delta: Int) {
        
        let firstLineRange = backingStore.mutableString.lineRange(for: editedRange)
        let maxRange = NSRange(location: editedRange.location + editedRange.length, length: 0)
        let lastLineRange = backingStore.mutableString.lineRange(for: maxRange)
        let fullRange = NSUnionRange(firstLineRange, lastLineRange)
        
        self.removed = parser.parse(backingStore.mutableString, in: fullRange)
        
    }
    
    private func toInsert(editedRange: NSRange, with delta: Int) {
        
        let newEditedRange = NSRange(location: editedRange.location, length: editedRange.length + delta)
        let firstLineRange = backingStore.mutableString.lineRange(for: newEditedRange)
        let extendedRange = NSRange(location: editedRange.location + editedRange.length + delta, length: 0)
        let lastLineRange = backingStore.mutableString.lineRange(for: extendedRange)
        let fullRange = NSUnionRange(firstLineRange, lastLineRange)
        
        self.inserted = parser.parse(backingStore.mutableString, in: fullRange)
        
    }
    
}

// ===================
// HIGHLIGHTING
// ===================
extension TextStorage {
    
    func highlight() {
        
        let firstLineRange = backingStore.mutableString.lineRange(for: editedRange)
        let extendedRange = NSRange(location: editedRange.location + editedRange.length, length: 0)
        let lastLineRange = backingStore.mutableString.lineRange(for: extendedRange)
        let fullRange = NSUnionRange(firstLineRange, lastLineRange)
        
        parser.highlight(theme: theme, backingStorage: self, in: fullRange)
        
    }
    
    
    
    
}

