//
//  TextViewController.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

protocol TaskTextViewControllerDelegate: class {
    func dataDidChange()
}

class TextViewController: NSViewController {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }
    
    @IBOutlet weak var textView: TaskTextView!
    
    weak var delegate: TaskTextViewControllerDelegate?
    
    var storage: [Task] = []
    var hashtags: Bag<String> = Bag<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        configure()
    }
    
    private func configure() {
        
        // ---------- textview ----------
        textView.delegate = self
        textView.autocompletionDelegate = self
        //textView.font = NSFont(name: "IBM Plex Mono", size: 17.0)
        //textView.typingAttributes = [.font: NSFont(name: "IBM Plex Mono", size: 17.0), .foregroundColor: NSColor.textColor]
        textView.insertionPointColor = NSColor.alert
        let layoutManager = TaskLayoutManager()
        layoutManager.delegate = self
        textView.textContainer?.replaceLayoutManager(layoutManager)
        textView.layoutManager?.allowsNonContiguousLayout = true
        
        //textView.textContainer?.maximumNumberOfLines = 100
        
        
        // ---------- text storage ----------
        let textStorage = TaskTextStorage()
        textStorage.delegate = self
        textStorage.taskDelegate = self
        textView.textContainer?.layoutManager?.replaceTextStorage(textStorage)
        
    }
    
    func reload(_ str: String) {
        
        textView.set(text: str)
        
        self.storage = []
        self.hashtags = Bag<String>()
        
        let parser = Parser()
        let tasks = parser.parse(string: str)
        self.insert(tasks)
    }
    
    func insert(_ tasks: [Task]) {
        let mentions = tasks.compactMap { (task) -> String? in
            return task.hashtag
        }
        hashtags.insert(mentions)
        storage.append(contentsOf: tasks)
    }
    
    func remove(_ tasks: [Task]) {
        let mentions = tasks.compactMap { (task) -> String? in
            return task.hashtag
        }
        hashtags.remove(mentions)
        for task in tasks {
            if let index = tasks.firstIndex(of: task) {
                storage.remove(at: index)
            } else {
                fatalError("TaskStorage don`t contains task = \(task)")
            }
        }
    }
    
}

extension TextViewController: TaskTextStorageDelegate {
    func taskTextStorage(insert tasks: [Task]) {
        self.insert(tasks)
    }
    
    func taskTextStorage(remove tasks: [Task]) {
        self.remove(tasks)
    }
}

extension TextViewController: NSLayoutManagerDelegate {
    
    /*
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUse action: NSLayoutManager.ControlCharacterAction, forControlCharacterAt charIndex: Int) -> NSLayoutManager.ControlCharacterAction {
        if let value = layoutManager.textStorage!.attribute(.isCollapsed, at: charIndex, effectiveRange: nil) as? Int, value == 1 {
            return .zeroAdvancement
        }
        return action
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>, properties props: UnsafePointer<NSLayoutManager.GlyphProperty>, characterIndexes charIndexes: UnsafePointer<Int>, font aFont: NSFont, forGlyphRange glyphRange: NSRange) -> Int {
        
        let properties = UnsafeMutablePointer<NSLayoutManager.GlyphProperty>(mutating: props)
        
        for i in 0..<glyphRange.length {
            let characterIndex = charIndexes[i]
            if let value = layoutManager.textStorage!.attribute(.isCollapsed, at: characterIndex, effectiveRange: nil) as? Int, value == 1 {
                print("charIndex = \(characterIndex) is collapsed")
                properties[characterIndex] = .null
            }
        }
        //properties[0] = .null
       // properties[1] = .null
       // properties[2] = .null
        layoutManager.setGlyphs(glyphs, properties: properties, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
        
        return glyphRange.length
    }
    */
}

extension TextViewController: NSTextStorageDelegate, NSTextViewDelegate {
    
    // ******** Text Storage Delegate ********
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
    }
    
    func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
    }
    
    override func textStorageDidProcessEditing(_ notification: Notification) {
        guard let textStorage = textView.textStorage as? TaskTextStorage else { return }
        if textStorage.observeChanging {
            delegate?.dataDidChange()
        }
        //parseGroups(backingStorage: textStorage)
    }
    
    func parseGroups(backingStorage: NSMutableAttributedString) {
        /*
        var indent: Int?
        let fullRange = backingStorage.mutableString.fullRange
        print(#function)
        let parser = Parser()
        
        backingStorage.mutableString.enumerateSubstrings(in: fullRange, options: [.reverse, .byLines]) { (substring, range, enclosingRange, stop) in
            let shifting = range.location
            if let (status, newIndent, statusRange) = parser.statusPrefix(in: substring!) {
                
                if status == .completed {
                    backingStorage.addAttribute(.prefix, value: Prefix.completed, range: statusRange.shifted(by: shifting))
                } else {
                    if indent != nil && newIndent < indent! {
                        print("isRoot")
                        backingStorage.addAttribute(.prefix, value: Prefix.root, range: statusRange.shifted(by: shifting))
                    } else {
                        backingStorage.addAttribute(.prefix, value: Prefix.task, range: statusRange.shifted(by: shifting))
                    }
                }
                
                indent = newIndent
            } else {
                indent = nil
            }
        }*/
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        return true
    }
    
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        print("clicked link at \(charIndex)")
        let parser = Parser()
        if let lineRange = textView.textStorage?.mutableString.lineRange(for: NSRange(location: charIndex, length: 0)) {
            
            let lineString = textView.string.substring(from: lineRange)
            print(lineString)
            let lineIndent = parser.parseTask(in: lineString, validateType: true)!.indent
            print("lineIndent = \(lineIndent)")
            let length = textView.string.count - lineRange.upperBound
            let endRange = NSRange(location: lineRange.upperBound, length: length)
            print("other part = \(textView.string.substring(from: endRange))")
            var upperBoundOfLastTask: Int?
            textView.textStorage?.mutableString.enumerateSubstrings(in: endRange, options: .byLines, using: { (substring, range, enclosingRange, stop) in
                print("substring = \(substring!)")
                if let task = parser.parseTask(in: substring!, validateType: true), lineIndent < task.indent {
                    upperBoundOfLastTask = enclosingRange.upperBound
                    print("subtask = \(task.string)")
                    print("indent = \(task.indent)")
                } else {
                    stop.pointee = ObjCBool(true)
                }
            })
            
            if let end = upperBoundOfLastTask {
                let foldingRange = NSRange(location: lineRange.upperBound, length: end - lineRange.upperBound)
                print("foldingRAnge = \(foldingRange)")
                //textView.textStorage!.addAttribute(.isCollapsed, value: 1, range: foldingRange)
                //textView.textStorage!.addAttribute(.foregroundColor, value: NSColor.red, range: foldingRange)
            }
            
        }
        return false
    }
    
}

extension TextViewController: TaskTextViewDelegate {
    
    func taskTextView() -> [String] {
        return []
    }
    
}





