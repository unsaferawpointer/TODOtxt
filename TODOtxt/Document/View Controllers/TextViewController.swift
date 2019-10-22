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
        textView.font = NSFont(name: "IBM Plex Mono", size: 15.0)
        textView.insertionPointColor = NSColor.alert
        //textView.textContainer?.replaceLayoutManager(TaskLayoutManager())
        textView.layoutManager?.allowsNonContiguousLayout = false
        //textView.layoutManager?.showsControlCharacters = true
        //textView.layoutManager?.showsInvisibleCharacters = true
        
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
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        return true
    }
    
}

extension TextViewController: TaskTextViewDelegate {
    
    func taskTextView(for element: Token) -> [String] {
        return []
    }
    
}





