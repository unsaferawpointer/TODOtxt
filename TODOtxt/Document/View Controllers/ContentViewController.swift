//
//  ContentViewController.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa



class ContentViewController: NSViewController {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
    var presentedData: Data {
        get {
            let str = backingStore.string
            return str.data(using: .utf8)!
        }
        set {
            backingStore.load(newValue)
        }
    }
    
    var backingStore: TodoStorage = TodoStorage(mentions: [.context,.project])
    // VIEWS
    @IBOutlet weak var contentView: BackgroundView!
    @IBOutlet weak var titleTextfield: NSTextField!
    @IBOutlet weak var textview: TextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        print(#function)
        
        // ---------- text storage ----------
        let textStorage = TextStorage()
        textStorage.delegate = self
        textStorage.dataDelegate = self
        textview.textContainer?.layoutManager?.replaceTextStorage(textStorage)
        
        // ---------- textview configuration ----------
        textview.completionDelegate = self
        textview.delegate = self
        
        textview.layoutManager?.allowsNonContiguousLayout = false
        
        textview.setUpLineNumberView()
        textview.insertionPointColor = NSColor.alert
        
        let font = NSFont(name: "Menlo", size: 13.0)
        textview.font = font
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.paragraphSpacing = 6.0
        //textview.defaultParagraphStyle = paragraphStyle
        textview.typingAttributes = [.font : font as Any, .paragraphStyle: paragraphStyle]
        textview.reload(with: backingStore.string)
        
        // ---------- other views configuration ----------
        contentView.backgroundColor = theme.background
        titleTextfield.textColor = theme.foreground
        
        invalidateTheme()
        
        // ---------- setup notifications ----------
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(_:)), name: .themeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appearanceDidChange(_:)), name: .appearanceDidChange, object: nil)
        
    }
    
    private func invalidateTheme() {
        contentView.backgroundColor = theme.background
        titleTextfield.textColor = theme.foreground
        textview.invalidateColorScheme()
        textview.reload(with: backingStore.string)
    }
    
    @objc func themeDidChange(_ notification: Notification) {
        print(#function)
        invalidateTheme()
    }
    
    @objc func appearanceDidChange(_ notification: Notification) {
        print(#function)
        invalidateTheme()
    }
    
    override func viewDidDisappear() {
        print(#function)
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension ContentViewController: SidebarDelegate {
    func selectedItemDidChange(newItem item: Item) {
        let newStr = backingStore.filtered(by: item.filter)
        textview.reload(with: newStr)
        titleTextfield.stringValue = item.name
    }
}

extension ContentViewController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        return true
    }
}

extension ContentViewController: TextStorageDataDelegate {
    
    func dataDidChanged(toInsert: [ToDo], toDelete: [ToDo]) {
        backingStore.insert(todos: toInsert)
        backingStore.remove(todos: toDelete)
    }
    
}

extension ContentViewController: AutoCompletionDelegate {
    func complete(element: Element) -> [String] {
        return backingStore.mentionStore.mentionKeys(for: element)
    }
    
}



extension ContentViewController: NSTextStorageDelegate {
    
    override func textStorageDidProcessEditing(_ notification: Notification) {
        guard let textStorage = textview.textStorage as? TextStorage else { return }
        if textStorage.observeChanging {
            document.updateChangeCount(.changeDone)
        }
        if let rulerView = textview.enclosingScrollView?.verticalRulerView as? RulerView {
            rulerView.invalidateMarks()
        }
        
    }
    
}
