//
//  TextViewController.swift
//  TODO txt
//
//  Created by subzero on 24/08/2019.
//  Copyright © 2019 antoncherkasov. All rights reserved.
//

import Cocoa

class TextViewController: NSViewController {
    
    var document: Document {
        return NSDocumentController.shared.document(for: view.window!) as! Document
    }
    
    @IBOutlet weak var infoTextField: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var theme: Theme {
        return Preferences.shared.theme
    }
    
    var grouping: Grouping = .commonDateStyle
    var refreshing: Bool = false
    var backingStore: Storage?
    
    // VIEWS
    @IBOutlet weak var contentView: BackgroundView!
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
        
        // ---------- other views configuration ----------
        contentView.backgroundColor = theme.background
        
        invalidateTheme()
        
        scrollView.contentView.postsBoundsChangedNotifications = true
        
        // ---------- setup notifications ----------
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(_:)), name: .themeDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appearanceDidChange(_:)), name: .appearanceDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(frameDidChange(_:)), name: NSView.boundsDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload(_:)), name: .badgeFilterDidChange, object: nil)
        
    }
    
    @objc func frameDidChange(_ sender: Any) {
        let frame = scrollView.contentView.frame
        let bounds = scrollView.contentView.bounds
        //print("frame = \(frame)")
        //print("bounds = \(bounds)")
        
        if bounds.origin.y < -100.0 {
            refreshing = true
            reload(self)
        }
        
    }
    
    @IBAction func sort(_ sender: NSMenuItem) {
        
        switch sender.identifier!.rawValue {
        case "project":
            grouping = .project
        case "context":
            grouping = .context
        case "priority":
            grouping = .priority
        case "due_date":
            grouping = .date
        case "status":
            grouping = .status
        case "due_date_state":
            grouping = .commonDateStyle
        default:
            break
        }
        
        reload(self)
    }
   
    
    @objc func reload(_ sender: Any) {
        
        guard backingStore != nil else { return }
        
        let newStr = backingStore!.string(by: grouping)
        textview.reload(with: newStr)
        updateInfo()
    }
    
    private func updateInfo() {
        let charactersLimit = backingStore?.CHARACTERS_LIMIT ?? 0
        let tasksLimit = backingStore?.TASKS_LIMIT ?? 0
        let tasksCount = backingStore?.storage.count ?? 0
        let charactersCount = textview.string.count 
        
        let info = String(format: "%d/%d tasks, %d/%d characters", arguments: [tasksCount, tasksLimit, charactersCount, charactersLimit])
        infoTextField.stringValue = info
    }
    

    
    private func invalidateTheme() {
        contentView.backgroundColor = theme.background
        textview.invalidateColorScheme()
        infoTextField.textColor = theme.foreground
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

extension TextViewController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let delta = (replacementString?.count ?? 0) - affectedCharRange.length
        return backingStore?.shouldChange(with: delta) ?? true
    }
}

extension TextViewController: TextStorageDataDelegate {
    func dataDidChanged(toInsert: [Task], toDelete: [Task]) {
        backingStore!.performOperation(inserted: toInsert, removed: toDelete)
    }
   
}

extension TextViewController: AutoCompletionDelegate {
    func complete(element: Element) -> [String] {
        return backingStore?.mentions(for: element) ?? []
    }
    
}



extension TextViewController: NSTextStorageDelegate {
    
    override func textStorageDidProcessEditing(_ notification: Notification) {
        guard let textStorage = textview.textStorage as? TextStorage else { return }
        if textStorage.observeChanging {
            document.updateChangeCount(.changeDone)
            updateInfo()
        }
        if let rulerView = textview.enclosingScrollView?.verticalRulerView as? RulerView {
            rulerView.invalidateMarks()
        }
        
    }
    
}
